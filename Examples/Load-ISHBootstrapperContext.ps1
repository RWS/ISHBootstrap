param(
    [Parameter(Mandatory=$true,ParameterSetName="Name")]
    [ValidateNotNullOrEmpty()]
    [string]$JSONFile,
    [Parameter(Mandatory=$true,ParameterSetName="Path")]
    [ValidateNotNullOrEmpty()]
    [string]$JSONPath,
    [Parameter(Mandatory=$true,ParameterSetName="Content")]
    [ValidateNotNullOrEmpty()]
    $JSON,
    [Parameter(Mandatory=$true,ParameterSetName="Content")]
    [ValidateNotNullOrEmpty()]
    [string]$FolderPath
)
try
{
    if($PSCmdlet.ParameterSetName -eq "Name")
    {
        $JSONPath="$PSScriptRoot\$JSONFile"
        $FolderPath=$PSScriptRoot
    }
    if($PSCmdlet.ParameterSetName -eq "Path")
    {
        $FolderPath=Split-Path -Parent $JSONPath
        $uri = [System.Uri]"file://$JSONPath"
        Write-Debug "jsonPath=$JSONPath"
        Write-Debug "uri=$($uri.AbsoluteUri)"

        $client = New-Object System.Net.Webclient
        $JSON = $client.DownloadString($uri.AbsoluteUri)
    }

    $variableName="__ISHBootstrapper_Data__"
	if($JSON -is [string])
    {
        $JSON=$JSON| ConvertFrom-Json
    }
    $JSON | Add-Member NoteProperty "FolderPath" -Value $FolderPath
    Set-Variable $variableName -Value $JSON -Scope Global -Force

    Write-Host "ISHBootstrapper initialized in variable $variableName."
}
finally
{

}