param(
    [Parameter(Mandatory=$true,ParameterSetName="Name")]
    [ValidateNotNullOrEmpty()]
    [string]$JSONFile,
    [Parameter(Mandatory=$true,ParameterSetName="Path")]
    [ValidateNotNullOrEmpty()]
    [string]$JSONPath
)
try
{
    if($PSCmdlet.ParameterSetName -eq "Name")
    {
        $JSONPath="$PSScriptRoot\$JSONFile"
    }
    $uri = [System.Uri]"file://$JSONPath"
    Write-Debug "jsonPath=$JSONPath"
    Write-Debug "uri=$($uri.AbsoluteUri)"

    $client = New-Object System.Net.Webclient
    $data = $client.DownloadString($uri.AbsoluteUri)

    $variableName="__ISHBootstrapper_Data__"
    Set-Variable $variableName -Value ($data| ConvertFrom-Json) -Scope Global -Force

    Write-Host "ISHBootstrapper initialized from $JSONPath in variable $variableName"
}
catch
{
    throw
}