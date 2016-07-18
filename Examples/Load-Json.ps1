param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$JSONFile
)

$jsonPath="$PSScriptRoot\$JSONFile"
$scriptPath=Resolve-Path "$PSScriptRoot\..\Source\Scripts\Helpers\Load-ISHBootstrapperContext.ps1"
& $scriptPath -DataPath "file://$jsonPath"