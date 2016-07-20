param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$JSONFile
)
try
{
    $jsonPath="$PSScriptRoot\$JSONFile"
    $uri = [System.Uri]"file://$jsonPath"
    Write-Debug "jsonPath=$jsonPath"
    Write-Debug "uri=$($uri.AbsoluteUri)"

    $client = New-Object System.Net.Webclient
    $data = $client.DownloadString($uri.AbsoluteUri)

    $variableName="__ISHBootstrapper_Data__"
    Set-Variable $variableName -Value ($data| ConvertFrom-Json) -Scope Global -Force

    Write-Host "ISHBootstrapper initialized from $JSONFile in variable $variableName"
}
catch
{
    throw
}