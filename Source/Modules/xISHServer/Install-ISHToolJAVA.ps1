. $PSScriptRoot\Get-ISHServerFolderPath.ps1

function Install-ISHToolJAVA 
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-D385255A-3644-485A-9B76-2D8695C0F000
    $fileNames=@("jre-8u60-windows-x64.exe","jdk-8u60-windows-x64.exe")
    $arguments=@(
        “/s”
    )

    foreach($fileName in $fileNames)
    {
        $filePath=Join-Path (Get-ISHServerFolderPath) $fileName

        Write-Debug "Installing $filePath"
        Start-Process $filePath -ArgumentList $arguments -Wait -Verb RunAs
        Write-Verbose "Installed $fileName"
    }

    [Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jre1.8.0_60", "Machine")
}