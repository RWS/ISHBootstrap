function Install-ISHToolMSXML4
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-EA97B03F-C33B-466E-A307-CA9F2B10B22D

    $fileName="MSXML.40SP3.msi"
    $filePath=Join-Path (Get-ISHServerFolderPath) $fileName
    $logFile=Join-Path $env:TEMP "$fileName.log"
    $arguments=@(
        "/package"
        $filePath
        “/qn”
        "/lv"
        $logFile
    )

    Write-Debug "Installing $fileName"
    Start-Process "msiexec" -ArgumentList $arguments -Wait
    Write-Verbose "Installed $fileName"
}