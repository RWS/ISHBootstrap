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

if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$serverScriptsPaths="$sourcePath\Server"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
$credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke
$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
$ishServerVersion=($ishVersion -split "\.")[0]

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$cleanBlock= {
    & taskkill /im DllHost.exe /f
    Write-Host "Killed DllHost.exe"

    $infoSharePath="C:\InfoShare"
    Write-Debug "infoSharePath=$infoSharePath"

    $ishDeployProgramDataPath=Join-Path "C:\ProgramData" "ISHDeploy"
    Write-Debug "ishDeployProgramDataPath=$ishDeployProgramDataPath"

    $ishServerProgramDataPath=Join-Path "C:\ProgramData" "ISHServer.$ishServerVersion"
    Write-Debug "ishServerProgramDataPath=$ishServerProgramDataPath"

    $ishDeployModuleName="ISHDeploy"
    Write-Debug "ishDeployModuleName=$ishDeployModuleName"
    $ishServerModuleName="ISHServer.$ishServerVersion"
    Write-Debug "ishServerModuleName=$ishServerModuleName"
    $ishAutomationModuleName="ISHServer.$ishServerVersion"
    Write-Debug "ishServerModuleName=$ishServerModuleName"

    Uninstall-Module $ishDeployModuleName -Force
    Write-Host "Uninstalled $ishDeployModuleName"
    Remove-Item $ishDeployProgramDataPath -Recurse -Force
    Write-Host "Removed $ishDeployProgramDataPath"

    Uninstall-Module $ishServerModuleName -Force
    Write-Host "Uninstalled $ishServerModuleName"
    Remove-Item $ishServerProgramDataPath -Recurse -Force
    Write-Host "Removed $ishServerProgramDataPath"

    Remove-Item $infoSharePath -Recurse -Force
    Write-Host "Removed $infoSharePath"

}

try
{

    if(-not $computerName)
    {
        & "$serverScriptsPaths\Helpers\Test-Administrator.ps1"
    }
    Invoke-CommandWrap -ComputerName $computerName -Credential $credential -ScriptBlock $cleanBlock -BlockName "Clean ISH" -UseParameters @("ishVersion","ishServerVersion")

}
finally
{
}
