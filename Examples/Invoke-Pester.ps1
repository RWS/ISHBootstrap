<#
# Copyright (c) 2014 All Rights Reserved by the SDL Group.
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

param(
    [Parameter(Mandatory=$false)]
    [switch]$Server=$false,
    [Parameter(Mandatory=$false)]
    [switch]$Deployment=$false,
    [Parameter(Mandatory=$false)]
    [switch]$Separate=$false,
    [Parameter(Mandatory=$false)]
    [ValidateSet("LegacyNUnitXml","NUnitXml")]
    [string]$OutputFormat="NUnitXml"
)
if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"
try
{

    . "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
    $computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
    $credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke

    . "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"
    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }
    else
    {
        if($credential)
        {
            $session=New-PSSession $computerName -Credential $credential
        }
        else
        {
            $session=New-PSSession $computerName
        }
        Invoke-CommandWrap -Session $session -BlockName "Initialize Debug/Verbose preference on $($Session.ComputerName)" -ScriptBlock {}
    }

    $ishDeployments=Get-ISHBootstrapperContextValue -ValuePath "ISHDeployment"
    $ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
    $folderPath=Get-ISHBootstrapperContextValue -ValuePath "FolderPath"
    $pesterResult=@{}

    $outputPath=Join-Path $env:TEMP "ISHBootstrap"
    if($computerName)
    {
        $outputPath=Join-path $outputPath $computerName
    }
    else
    {
        $outputPath=Join-path $outputPath $env:COMPUTERNAME
    }

    function InvokePester ([string]$deploymentName, [string[]]$pesterScripts)
    {
        $parameters=@{
            "ISHVersion" = $ishVersion
        }
        if($deploymentName)
        {
            $parameters.DeploymentName=$deploymentName
        }
        if($Session)
        {
            $parameters.Session = $session
        }
        $script=@{
            Parameters = $parameters
        }

        $pesterResult=@()
        if($Separate)
        {
            $pesterScripts| ForEach-Object {
                $script.Path=$_
                $pesterHash=@{
                    Script=$script
                    PassThru=$true
                }
                $pesterResult+=Invoke-Pester @pesterHash
            }
        }
        else
        {
            $testContainerPath=$outputPath
            if($DeploymentName)
            {
                $testContainerPath=Join-path $testContainerPath $DeploymentName
            }
            else
            {
                $testContainerPath=Join-path $testContainerPath "Server"
            }
            $testContainerPath=Join-Path $testContainerPath (Get-Date -Format "yyyyMMdd.hhmmss")
            if(Test-Path $testContainerPath)
            {
                Remove-Item $testContainerPath -Recurse -Force
            }
            New-Item -Path $testContainerPath -ItemType Directory |Out-Null
            $extraFolderPathToCopy=@()
            $i=0
            $pesterScripts| ForEach-Object {
                $sourceFolderPath=Split-Path -Path $_ -Parent
                $extraFolderPathToCopy+=Get-ChildItem -Path $sourceFolderPath -Directory |Select-Object -ExpandProperty FullName

                $sourceFileName=Split-Path -Path $_ -Leaf
                $prefix=$i.ToString("000")
                $targetPath=Join-Path $testContainerPath "$prefix.$sourceFileName"
                Copy-Item -Path $_ -Destination $targetPath
                $i++
            }
            $extraFolderPathToCopy=$extraFolderPathToCopy|Select-Object -Unique
            Copy-Item -Path $extraFolderPathToCopy -Destination $testContainerPath -Recurse
            $script.Path=$testContainerPath
            $pesterHash=@{
                Script=$script
                PassThru=$true
                OutputFormat=$OutputFormat
            }
            $outputFileNameSegments=@()
            $outputFileNameSegments+=Get-Date -Format "yyyyMMdd.hhmmsss"
            if($DeploymentName)
            {
                $outputFileNameSegments+=$deploymentName
                #$pesterHash.TestName=$deploymentName
            }
            else
            {
                $outputFileNameSegments+="Server"
                #$pesterHash.TestName="Server"
            }
            $outputFileNameSegments+="TestResults"
            $outputFileNameSegments+="xml"
            $outputFilePath=Join-Path $outputPath ($outputFileNameSegments -join ".")
            
            $pesterHash.OutputFile=$outputFilePath

            $result=Invoke-Pester @pesterHash
            $result | Add-Member -Name "TestResultPath" -Value $outputFilePath -MemberType NoteProperty
            $pesterResult+=$result
            Write-Verbose "$OutputFormat test result available in $outputFilePath"
        }

        return $pesterResult
    }

    $pesterResult=@{}
    if($Server)
    {
        $scriptsToExecute=@()
        $pester=Get-ISHBootstrapperContextValue -ValuePath "Pester" -DefaultValue $null
        if((-not $pester) -or ($pester.Count -eq 0))
        {
            Write-Warning "No global test scripts defined."
            continue
        }
        $pester | ForEach-Object {
            $scriptFileName=$_
            $scriptPath=Join-Path $folderPath $scriptFileName
            if(Test-Path $scriptPath)
            {
                $scriptsToExecute+=$scriptPath
            }
            else
            {
                Write-Warning "$scriptPath not found. Skipping."
            }
        }
        $pesterResult["Server"]=InvokePester $null $scriptsToExecute
    }

    if($Deployment)
    {
        foreach($ishDeployment in $ishDeployments)
        {
            $deploymentName=$ishDeployment.Name
            $scriptsToExecute=@()
            if((-not $ishDeployment.Pester) -or ($ishDeployment.Pester.Count -eq 0))
            {
                Write-Warning "No deploymen specific test scripts defined for $deploymentName"
                continue
            }
            $ishDeployment.Pester | ForEach-Object {
                $scriptFileName=$_
                $scriptPath=Join-Path $folderPath $scriptFileName
                if(Test-Path $scriptPath)
                {
                    $scriptsToExecute+=$scriptPath
                }
                else
                {
                    Write-Warning "$scriptPath not found. Skipping."
                }
            }
            $pesterResult[$deploymentName]=InvokePester $deploymentName $scriptsToExecute
        }
    }
    foreach($key in $pesterResult.Keys)
    {
        $pesterResult[$key]|Select-Object @{Name="Name";Expression={$key}},TotalCount,PassedCount,FailedCount,SkippedCount,PendingCount,Time,TestResultPath
    }
}
finally
{
    if($session)
    {
        $session|Remove-PSSession
    }
}
