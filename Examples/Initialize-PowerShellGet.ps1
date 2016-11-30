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
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
$credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke

if(-not $computerName)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

& $scriptsPaths\PackageManagement\Install-PackageManagement.ps1 -Computer $computerName -Credential $credential
& $scriptsPaths\PackageManagement\Install-NugetPackageProvider.ps1 -Computer $computerName -Credential $credential

$psRepository=Get-ISHBootstrapperContextValue -ValuePath "PSRepository"
$psRepository |ForEach-Object {
    & $scriptsPaths\PowerShellGet\Register-Repository.ps1 -Computer $computerName -Credential $credential -Name $_.Name -SourceLocation $_.SourceLocation -PublishLocation $_.PublishLocation -InstallationPolicy $_.InstallationPolicy
}

$installProcessExplorer=Get-ISHBootstrapperContextValue -ValuePath "InstallProcessExplorer" -DefaultValue $false
if($installProcessExplorer)
{
    & $scriptsPaths\Helpers\Install-ProcessExplorer.ps1 -Computer $computerName -Credential $credential
}
