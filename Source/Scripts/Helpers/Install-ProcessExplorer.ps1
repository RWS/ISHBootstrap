Param (
    [Parameter(Mandatory = $false)]
    [string]$Computer=$null
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$block= {
    $targetPath=Join-Path $env:ProgramFiles "ProcessExplorer"
    if(Test-Path $targetPath)
    {
        Write-Warning "Process explorer already installed at $targetPath"
        return
    }
    $downloadPath=Join-Path $env:TEMP "ProcessExplorer.zip"
    $uri = "https://download.sysinternals.com/files/ProcessExplorer.zip"
    Write-Debug "uri=$($uri.AbsoluteUri)"
    $client = New-Object System.Net.Webclient
    $client.DownloadFile($uri,$downloadPath)
    Write-Verbose "Downloaded file $($uri.AbsoluteUri) to $downloadPath"

    Write-Debug "Expanding $downloadPath to $targetPath"
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')|Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($downloadPath, $targetPath)|Out-Null
    Write-Verbose "Expanded $downloadPath to $targetPath"
    Write-Host "Process explorer available at $targetPath"
}

try
{
    Invoke-CommandWrap -ComputerName $Computer -ScriptBlock $block -BlockName "Install Process Explorer"
}
finally
{
}

Write-Separator -Invocation $MyInvocation -Footer