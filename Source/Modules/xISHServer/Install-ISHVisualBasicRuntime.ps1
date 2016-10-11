function Install-ISHVisualBasicRuntime
{
    $osInfo=Get-ISHOSInfo
    if($osInfo.IsCore)
    {
        # Workaround for Windows Server 2016 core
        # https://social.technet.microsoft.com/Forums/windowsserver/en-US/9b0f8911-07f4-420f-9e48-d31915f91528/msvbvm60dll-missing-in-core?forum=winservercore
        Write-Warning "This is a workaround for making the Visual Basic runtime available on $($osInfo.Caption) Core"

        $fileName="vbrun60sp6.exe"
        $filePath=Join-Path (Get-ISHServerFolderPath) $fileName
        $arguments=@(
            "/Q"
        )

        Write-Debug "Installing $fileName"
        Start-Process $filePath -ArgumentList $arguments -Wait -Verb RunAs
        Write-Verbose "Installed $fileName"
    }
}