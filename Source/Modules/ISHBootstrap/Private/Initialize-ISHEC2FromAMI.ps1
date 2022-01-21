<#
# Copyright (c) 2021 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#>

<#
.Synopsis
   Initialize the ISHBootstrap's "almost ready" state
.DESCRIPTION
   Initialize the ISHBootstrap's "almost ready" state by replacing the hostname.
.EXAMPLE
   Initialize-ISHEC2FromAMI -Hostname hostname
#>
Function Initialize-ISHEC2FromAMI {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$HostName,
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "Testing if the EC2 host has been once initialized from AMI"
        # This cmdlet cannot execute twice on the same host
        $ISHDeploymentSplat = @{}
        $ISHDeploymentNameSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
            $ISHDeploymentNameSplat = @{Name = $ISHDeployment}
        }
        if (Test-ISHRequirement -Marker -Name "ISH.EC2InitializedFromAMI" @ISHDeploymentSplat) {
            throw "EC2 is already initialized from AMI"
        }
        Write-Debug "EC2 host has not been once initialized from AMI"
    }

    process {
        #region Locate InstallTool log file
        $ishCDPath = Get-ISHCD -ListAvailable | Where-Object -Property IsExpanded -EQ $true | Select-Object -ExpandProperty ExpandedPath
        Write-Debug "ishCDPath=$ishCDPath"
        $installToolFolder = Join-Path -Path $ishCDPath -ChildPath __InstallTool
        Write-Debug "installToolFolder=$installToolFolder"
        $installToolLogPath = Get-ChildItem -Path $installToolFolder -Filter "InstallTool*.log" | Sort-Object -Property LastWriteTime -Descending | Select-Object -ExpandProperty FullName -First 1
        Write-Debug "installToolLogPath=$installToolLogPath"
        #endregion

        #region Build regular Expression to extract processed file paths for machinename,localservicehostname and basehostname input parameters
        $deployment = Get-ISHDeployment @ISHDeploymentNameSplat
        # Because InstallTool was ported to Nlog on version 13, the lines are a bit different.
        # Notice that the "caller" is different
        if ($deployment.SoftwareVersion.Major -eq 12) {
            # Example log line (minLevel=Debug)
            # 20170725.124043 DEB PlaceHolders::Replace:path - 'C:\InfoShare\12.0.4\_Workspace\AppSQL\TrisoftSolrLucene\Configuration\StartOptimize.bat' - machinename=MECDEVASAR03
            $methodPart = "(PlaceHolders::Replace:path - )"
        }
        elseif ($deployment.SoftwareVersion.Major -eq 13) {
            # Example log line (minLevel=Debug)
            # 20170810 09:20:09.885	Debug	InstallTool.Helpers.PlaceHolders.ReplaceFilePath	'C:\InfoShare\13.0.0\ISH\_Workspace\AppSQL\BackgroundTask\Configuration\StartConsole.bat' - machinename=MECDEVASAR03	[]
            $methodPart = "(InstallTool\.Helpers\.PlaceHolders\.ReplaceFilePath)[\t ]+"
        }
        else {
            # Example log line (minLevel=Info)
            # 20190311 01:26:06.468	Info	InstallTool.Helpers.TrisoftSetupUtilitiesLogger.WriteInfo	'D:\InfoShare\_Workspace\AppCore\Utilities\InstallTools\NET\2.0\comappassemblydll.bat' (3 replacements)	[]
            $methodPart = "(InstallTool\.Helpers\.TrisoftSetupUtilitiesLogger\.WriteInfo)[\t ]+"
        }
        Write-Debug "methodPart=$methodPart"

        if (($deployment.SoftwareVersion.Major -eq 12) -or ($deployment.SoftwareVersion.Major -eq 13)) {
            # These parameters are derived from the values of
            # baseurl=https://MockHostName<
            # localservicehostname=MockLocalServiceHostName
            # We are going to search all files that had one these inputparameters resolved.
            $parameterNames = @(
                "baseurl"
                "localservicehostname"
                "issuerwstrustendpointurl"
                "issuerwstrustmexurl"
                "issuerwsfederationendpointurl"
                "basehostname"
                "issuerwstrustendpointurl_normalized"
                "machinename"
            )
            $regex = "[A-Za-z0-9\.\t: ]+$methodPart'(?<Path>([A-Za-z0-9:\-_\\\.]+))' - ($(($parameterNames |ForEach-Object {"($_=)"}) -join '|'))"
        }
        else {
            $regex = "[A-Za-z0-9\.\t: ]+$methodPart['``](?<Path>([A-Za-z0-9:\-_\\\.]+))['``]"
        }

        Write-Debug "regex=$regex"
        #endregion

        #region Find files to process
        $allMatches = Select-String -Path $installToolLogPath -Pattern $regex -AllMatches
        $filePathsToProcess = $allMatches.Matches.Groups | Where-Object -Property Name -EQ Path | Select-Object -ExpandProperty Value
        Write-Debug "filePathsToProcess.Count=$($filePathsToProcess.Count)"

        # Because install tool resolves parameters inside the _Workspace folder, we need to adapt the path to match the actuall installation
        $filePathsToProcess = $filePathsToProcess | ForEach-Object {
            $newPath = $_.Replace("_Workspace\", "")
            Write-Debug "$_ converted to $newPath"
            $newPath
        }

        # Add files from Program Files install folder
        $installToolInputParameters = Get-ChildItem -Path (Join-Path ${env:ProgramFiles(x86)} "Trisoft\InstallTool") -Filter inputparameters.xml -Recurse | Select-Object -ExpandProperty FullName
        $backupPath = Get-StageFolderPath -BackupName $PSCmdlet.MyInvocation.MyCommand.Name @ISHDeploymentSplat
        Write-Debug "backupPath=$backupPath"
        $installToolInputParameters | ForEach-Object {
            Write-Debug "Copying $_ to $backupPath"
            Copy-Item -Path $_ -Destination $backupPath
        }
        $filePathsToProcess += $installToolInputParameters
        #endregion

        #region prepare replacement matrix
        $replacementMatrix = @(

            # basehostname
            @{
                CurrentValue = Get-ISHDeploymentParameters -Name basehostname -ValueOnly @ISHDeploymentSplat
                NewValue     = $HostName
            }
            # localservicehostname
            @{
                CurrentValue = Get-ISHDeploymentParameters -Name localservicehostname -ValueOnly @ISHDeploymentSplat
                NewValue     = $env:COMPUTERNAME
            }
            # machinename
            @{
                CurrentValue = Get-ISHDeploymentParameters -Name machinename -ValueOnly @ISHDeploymentSplat
                NewValue     = $env:COMPUTERNAME
            }
        ) | Where-Object {
            # Take no action if the values haven't changed
            $_.CurrentValue -ne $_.NewValue
        }

        $replacementMatrix | ForEach-Object {
            Write-Debug "Replacing CurrentValue=$($_.CurrentValue) with NewValue=$($_.NewValue)"
        }
        #endregion

        #region Replace mock parameters in files
        $filePathsToProcess | ForEach-Object {
            Write-Debug "Processing $_"
            if (-not (Test-Path -Path $_)) {
                Write-Warning "Following file was not found and will not be processed: $_"
            }
            else {
                $textInFile = [System.IO.File]::ReadAllText($_)
                $mustSaveFile = $false
                foreach ($matrix in $replacementMatrix) {
                    if ($textInFile.IndexOf($matrix.CurrentValue, [System.StringComparison]::OrdinalIgnoreCase) -gt -1) {
                        $textInFile = $textInFile.Replace($matrix.CurrentValue, $matrix.NewValue)
                        $mustSaveFile = $true
                    }
                }
                Write-Debug "mustSaveFile=$mustSaveFile"
                if ($mustSaveFile) {
                    [System.IO.File]::WriteAllText($_, $textInFile)
                    Write-Verbose "$_ saved"
                }
                else {
                    Write-Debug "No changes for $_"
                }
            }
        }
        #endregion

        #region Routing the hostname to 127.0.0.1
        # TODO StayLocal
        $null = Add-HostEntry -Name $HostName -Address 127.0.0.1 -Comment "From $($PSCmdlet.MyInvocation.MyCommand.Name)"
        Write-Verbose "Add host entry for routing $HostName to 127.0.0.1"
        #endregion

        #region Clean ISHDeploy's folder structure
        $packagesPath = Get-ISHPackageFolderPath @ISHDeploymentSplat
        Write-Debug "packagesPath=$packagesPath"
        $folderToRemove = Resolve-Path -Path "$packagesPath\..\.."
        Write-Debug "folderToRemove=$folderToRemove"
        Remove-Item -Path "$folderToRemove" -Recurse -Force
        Write-Verbose "$folderToRemove removed"

        # Now make sure that ISHDeploy knows that it is stopped
        Stop-ISHDeployment @ISHDeploymentSplat

        #endregion

        Write-Debug "Setting marker ISH.EC2InitializedFromAMI, to avoid re-execution on the same host"
        Set-ISHMarker -Name "ISH.EC2InitializedFromAMI" @ISHDeploymentSplat
    }
    end {

    }
}
