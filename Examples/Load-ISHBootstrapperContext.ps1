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
	$json=$data| ConvertFrom-Json
    $json | Add-Member NoteProperty "FolderPath" -Value (Split-Path -Parent $JSONPath)
    $json | Add-Member NoteProperty "FileName" -Value (Split-Path -Leaf $JSONPath)
    Set-Variable $variableName -Value $json -Scope Global -Force

    Write-Host "ISHBootstrapper initialized from $JSONPath in variable $variableName."
}
finally
{

}