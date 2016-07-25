. $PSScriptRoot\Get-ISHServerFolderPath.ps1

function Install-ISHToolVisualCPP 
{
    $fileName="NETFramework2013_4.5_MicrosoftVisualC++Redistributable_(vcredist_x64).exe"
    $filePath=Join-Path (Get-ISHServerFolderPath) $fileName
    $logFile=Join-Path $env:TEMP "$FileName.log"
    $arguments=@(
        "/install"
        "/quiet"
        "/log"
        "$logFile"
    )

    Write-Debug "Installing $filePath and logging to $logFile"
    Start-Process $filePath -ArgumentList $arguments -Wait -Verb RunAs
    Write-Verbose "Installed $fileName"
}