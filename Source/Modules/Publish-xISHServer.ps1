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
        $build+=$date.ToString("HHmmss")
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
