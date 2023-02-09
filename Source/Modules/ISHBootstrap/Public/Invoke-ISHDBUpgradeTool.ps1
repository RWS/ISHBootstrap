<#
# Copyright (c) 2022 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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
    Invoke the DBUpgradeTool executable.
.DESCRIPTION
    This cmdlet helper invokes DBUpgradeTool using provided parameters.
.EXAMPLE
    Invoke-ISHDBUpgradeTool -Upgrade
.EXAMPLE
    Invoke-ISHDBUpgradeTool -Upgrade -Credential PSCredential
#>
Function Invoke-ISHDBUpgradeTool {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        #region TODO LegacyCode12
        [Parameter(Mandatory = $true, ParameterSetName = "Upgrade - ISH12")]
        #endregion
        [Parameter(Mandatory = $true, ParameterSetName = "Upgrade")]
        [switch]$Upgrade,
        #region TODO LegacyCode12
        [Parameter(Mandatory = $true, ParameterSetName = "Upgrade - ISH12")]
        [PSCredential]$Credential,
        [Parameter(Mandatory = $true, ParameterSetName = "Setup")]
        [switch]$Setup,
        [Parameter(Mandatory = $true, ParameterSetName = "Setup")]
        [ValidateScript( { Test-Path $_ })]
        [string]$SetupXMLPath,
        [Parameter(Mandatory = $false, ParameterSetName = "Upgrade - ISH12")]
        [Parameter(Mandatory = $false, ParameterSetName = "Upgrade")]
        [Parameter(Mandatory = $false, ParameterSetName = "Setup")]
        [string]$ISHDeployment
        #endregion
    )

    begin {

        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        Write-Debug "Upgrade=$Upgrade"
        Write-Debug "Setup=$Setup"
        $ISHDeploymentSplat = @{}
        $ISHDeploymentNameSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
            $ISHDeploymentNameSplat = @{Name = $ISHDeployment}
        }

    }

    process {
        $deployment = Get-ISHDeployment @ISHDeploymentNameSplat
        $inputParametersPath = Get-ISHInputParametersItem @ISHDeploymentSplat| Select-Object -ExpandProperty FullName
        Write-Debug "inputParametersPath=$inputParametersPath"

        $applicationName = $deployment.Name.Replace("InfoShare", "InfoShareAuthor")
        Write-Debug "applicationName=$applicationName"

        $dbUpgradeToolFolder = Join-Path -Path $deployment.AppPath -ChildPath Setup\DBUpgradeTool
        Write-Debug "dbUpgradeToolFolder=$dbUpgradeToolFolder"

        $dbUpgradeToolPath = Join-Path -Path $dbUpgradeToolFolder DBUpgradeTool.exe
        Write-Debug "dbUpgradeToolPath=$dbUpgradeToolPath"

        $mustExecuteDBUpgradeTool = $false
        switch ($PSCmdlet.ParameterSetName) {
            'Setup' {
                $dbUpgradeToolArgs = @(
                    "-Setup"
                    "--applicationname"
                    $applicationName
                    "--path"
                    $SetupXMLPath
                )

                $mustExecuteDBUpgradeTool = $true
            }
            { $_ -like 'Upgrade*' } {
                $dbUpgradeToolArgs = @(
                    "-Upgrade"
                    "--inputparameters"
                    $inputParametersPath
                    "--applicationname"
                    $applicationName
                )

                #region TODO LegacyCode12
                if ($deployment.SoftwareVersion.Major -lt 13) {
                    $networkCredential = $Credential.GetNetworkCredential();
                    $username = $networkCredential.UserName
                    $password = $networkCredential.Password
                    $dbUpgradeToolArgs += @(
                        "--user"
                        $username
                        "--password"
                        $password
                    )
                }
                #endregion

                $ishDBVersion = Get-ISHDatabaseVersion @ISHDeploymentSplat
                Write-Debug "ishDBVersion=$ishDBVersion"
                [int]$ishDBVersionMajor = ($ishDBVersion -split '\.')[0]
                Write-Debug "ishDBVersionMajor=$ishDBVersionMajor"
                [int]$ishDBVersionRevision = ($ishDBVersion -split '\.')[2]
                Write-Debug "ishDBVersionRevision=$ishDBVersionRevision"

                if ($ishDBVersionMajor -lt 12) {
                    throw "Database's version $ishDBVersion must be at least 12.0.0"
                }
                $configurationData = Get-ISHCoreConfiguration @ISHDeploymentSplat                #region TODO ISH Unreleased
                if ($configurationData.Database.FromVersion) {
                    $mustExecuteDBUpgradeTool = $true
                    $dbUpgradeToolArgs += @(
                        "--fromversion"
                        $configurationData.Database.FromVersion
                    )
                }
                elseif ($ishDBVersionMajor -lt $deployment.SoftwareVersion.Major) {
                    # Database version is behind deployment's
                    $mustExecuteDBUpgradeTool = $true
                }
                elseif (($ishDBVersionMajor -eq $deployment.SoftwareVersion.Major) -and ($ishDBVersionRevision -lt $deployment.SoftwareVersion.Revision)) {
                    # Database version is behind deployment's
                    $mustExecuteDBUpgradeTool = $true
                }
                elseif (($ishDBVersionMajor -eq $deployment.SoftwareVersion.Major) -and ($ishDBVersionRevision -eq $deployment.SoftwareVersion.Revision)) {
                    # Database version is on par with deployment's
                    # Unrealised service packs are not acknowledged
                    $mustExecuteDBUpgradeTool = $false
                    Write-Verbose "Database version $ishDBVersion is on par with deployment' s $($deployment.SoftwareVersion)"
                }
                else {
                    throw "Database's version $ishDBVersion is ahead of deployment's $($deployment.SoftwareVersion)"
                }
                #endregion

                #region TODO ISH Unreleased
                # if the database doesn't seem to require an upgrade and the deployment is pre-release 13
                # then make sure we execute with upgrade
                if ((-not $mustExecuteDBUpgradeTool) -and ($deployment.SoftwareVersion.Major -eq 13)) {
                    Write-Warning "$($deployment.SoftwareVersion.Major) is a pre-released version. Making sure database is upgraded from 12.0.0"
                    $mustExecuteDBUpgradeTool = $true

                    # Database is required to be on 12.0.0 before introduced to the AWS ecosystem
                    $dbUpgradeToolArgs += @(
                        "--fromversion"
                        "12.0.0"
                    )
                }
                #endregion
            }
            Default {
                throw "Not supported"
            }
        }
        Write-Debug "mustExecuteDBUpgradeTool=$mustExecuteDBUpgradeTool"

        Write-Verbose "Invoking $dbUpgradeToolPath $($dbUpgradeToolArgs -join ' ')"
        if ($pscmdlet.ShouldProcess("$dbUpgradeToolPath")) {
            $wid = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            $prp = new-object System.Security.Principal.WindowsPrincipal($wid)
            $adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator

            if ($mustExecuteDBUpgradeTool) {
                # Check for Adminitrator rights required by DBUpgradeTool
                if ($prp.IsInRole($adm)) {
                    & $dbUpgradeToolPath $dbUpgradeToolArgs 2>&1
                    Write-Debug "LASTEXITCODE=$LASTEXITCODE"
                    $dbUpgradeToolLogPath = Get-ChildItem -Path $dbUpgradeToolFolder -Filter "DBUpgradeTool*.log" | Sort-Object -Property LastWriteTime -Descending | Select-Object -ExpandProperty FullName -First 1
                    Write-Debug "dbUpgradeToolLogPath=$dbUpgradeToolLogPath"

                    $failReason = $null
                    if ($LASTEXITCODE -ne 0) {
                        $failReason = "Exited with $LASTEXITCODE"
                    }
                    else {
                        #region TODO DBUT-Error
                        Write-Verbose "Non-zero exit code. Looking inside log file for error entries"

                        # Check if the log file contains FAILED entries
                        $regEx = @(
                            "(\[DBUT-FAILED\])" # Common stamp. Implicit contract between sql scripts and C#
                            "(.+ Error .+)" # ISH.13 NLOG style error line
                            "(.+ ERR .+)" # ISH.12 non NLOG style error line
                        ) -join "|"
                        Write-Debug "regEx=$regEx"
                        $errorLines = Select-String -Path "$dbUpgradeToolLogPath" -Pattern $regEx
                        if ($errorLines) {
                            Write-Warning "Matched $regEx entries in $dbUpgradeToolLogPath"
                            $errorLines | ForEach-Object {
                                Write-Warning $_
                            }
                            $failReason = "Error entries detected in log file"
                        }
                        #endregion
                    }

                    if ($failReason) {
                        Write-Warning "DBUpgradeTool.exe log file available in $dbUpgradeToolLogPath"
                        throw "Failed DBUpgradeTool.exe. Reason: $failReason"
                    }
                }
                else {
                    throw "Process should have elevated status to execute $dbUpgradeToolPath"
                }
            }
        }

    }

    end {

    }
}