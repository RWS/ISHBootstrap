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

Param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("xISHServer.12","xISHServer.13")]
    [string]$ModuleName,
    [Parameter(Mandatory=$true)]
    [string]$Repository,
    [Parameter(Mandatory=$true)]
    [string]$APIKey,
    [Parameter(Mandatory=$false,ParameterSetName="With Build Number")]
    [switch]$BuildNumber=$false,
    [Parameter(Mandatory=$false,ParameterSetName="With Build Number")]
    [switch]$TimeStamp=$false
)
$major=0
$minor=0

if($BuildNumber)
{
    $patch=0
    $date=(Get-Date).ToUniversalTime()
    $build=[string](1200 * ($date.Year -2015)+$date.Month*100+$date.Day)
    if($TimeStamp)
    {
        $build+=$date.ToString("HHmm")
    }
    $version="$major.$minor.$build.$patch"    
}
else
{
    $version="$major.$minor"    
}

$author="Alex Sarafian"
$company="SDL Plc"
$copyright="(c) $($date.Year) $company. All rights reserved."
$description="A module to help automate installation of prerequisites for Content Manager"

$sourcePath=Resolve-Path "$PSScriptRoot\xISHServer"

$psm1File=Get-ChildItem $sourcePath -Filter "$ModuleName.psm1"

$publishPath=Join-Path $env:TEMP PublishModules
if(-not (Test-Path $publishPath))
{
    New-Item $publishPath -ItemType Directory|Out-Null
}

Remove-Item "$publishPath\*" -Recurse -Force

$modulePath=Join-Path $publishPath $ModuleName
New-Item $modulePath -ItemType Directory|Out-Null
$psm1File | Copy-Item  -Destination $modulePath

$psd1Path=Join-Path $modulePath "$ModuleName.psd1"
$manifestHash=@{
    "Author"=$author;
    "Copyright"=$copyright;
    "RootModule"=$psm1File.Name;
    "Description"=$description;
    "ModuleVersion"=$version;
    "Path"=$psd1Path;
}

New-ModuleManifest  @manifestHash 

$moduleContent=$psm1File | Get-Content
$moduleContent |ForEach-Object {
    if($_ -match '\.+ \$PSScriptRoot\\*(?<ps1>.*-.*\.ps1)')
    {
        $cmdletFileName=$Matches["ps1"]
        Copy-Item "$sourcePath\$cmdletFileName" -Destination $modulePath
    }
}

Publish-Module -Path $modulePath -Repository $Repository -NuGetApiKey $APIKey
