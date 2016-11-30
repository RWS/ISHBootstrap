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

if(-not $computerName)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

$webCertificate=Get-ISHBootstrapperContextValue -ValuePath "WebCertificate"
$parameters=@(
    "-CertificateAuthority `"$($webCertificate.Authority)`""
)
if($webCertificate.OrganizationalUnit)
{
    $parameters+="-OrganizationalUnit `"$($webCertificate.OrganizationalUnit)`""
}
if($webCertificate.Organization)
{
    $parameters+="-Organization `"$($webCertificate.Organization)`""
}
if($webCertificate.Locality)
{
    $parameters+="-Locality `"$($webCertificate.Locality)`""
}
if($webCertificate.State)
{
    $parameters+="-State `"$($webCertificate.State)`""
}
if($webCertificate.Country)
{
    $parameters+="-Country `"$($webCertificate.Country)`""
}
$scriptLine="Initialize-Remote.ps1 "+ ($parameters -join ' ')



if($computerName)
{
    $targetPath="\\$computerName\C$\Users\$env:USERNAME\Documents\WindowsPowerShell\"
    if(-not (Test-Path $targetPath))
    {
        New-Item $targetPath -ItemType Directory | Out-Null
    }
    Copy-Item -Path "$scriptsPaths\Remote\Initialize-Remote.ps1" -Destination $targetPath -Force
    
    Write-Host "Login to $Computer and execute locally C:\Users\$env:USERNAME\Documents\WindowsPowerShell\$scriptLine"
}
else
{
    Write-Host "Executing $scriptsPaths\Remote\$scriptLine"
    & "$scriptsPaths\Remote\$scriptLine"
}
