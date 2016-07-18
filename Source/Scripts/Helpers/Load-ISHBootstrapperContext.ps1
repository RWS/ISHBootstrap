param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$DataPath
)
try
{
    $client = New-Object System.Net.Webclient
    Write-Debug "Downloading $DataPath"
    $uri = [System.Uri]$DataPath
    $data = $client.DownloadString($uri.AbsoluteUri)
    Write-Verbose "Downloaded $DataPath"

    $variableName="__ISHBootstrapper_Data__"
    Set-Variable $variableName -Value ($data| ConvertFrom-Json) -Scope Global -Force

    Write-Host "ISHBootstrapper initialized from $DataPath in variable $variableName"
}
catch
{
    throw
}