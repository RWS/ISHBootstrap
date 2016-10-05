. $PSScriptRoot\Get-ISHServerFolderPath.ps1

function Install-ISHToolDotNET 
{
    $osInfo=Get-ISHOSInfo
    if($osInfo.Version -eq "2016")
    {
        Write-Verbose "Assuming .NET 4.6.2 is installed on $($osInfo.Caption)"
    }
    else
    {
        $fileName="NETFramework2015_4.6.1.xxxxx_(NDP461-KB3102436-x86-x64-AllOS-ENU).exe"
        $filePath=Join-Path (Get-ISHServerFolderPath) $fileName
        $logFile=Join-Path $env:TEMP "$FileName.htm"
        $arguments=@(
            "/q"
            "/norestart"
            "/log"
            "$logFile"
        )

        Write-Debug "Installing $filePath"
        Start-Process $filePath -ArgumentList $arguments -Wait -Verb RunAs
        Write-Verbose "Installed $fileName"
        Write-Warning "You must restart the server before you proceed."
    }
}