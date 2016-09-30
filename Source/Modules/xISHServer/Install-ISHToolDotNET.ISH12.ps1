function Install-ISHToolDotNET 
{
    $osInfo=Get-ISHOSInfo
    Write-Warning "Assuming .NET 4.5 is installed on $($osInfo.Caption)"
}
