function Install-ISHToolDotNET 
{
    $osInfo=Get-ISHOSInfo
    Write-Verbose "Assuming .NET 4.5 is installed on $($osInfo.Caption)"
}
