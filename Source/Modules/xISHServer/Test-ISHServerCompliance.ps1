function Test-ISHServerCompliance
{
    $osInfo=Get-ISHOSInfo
    if($osInfo.IsServer)
    {
        $isSupported=$osInfo.Version -in '2016','2012 R2'
    }
    else
    {
        $isSupported=$osInfo.Version -in '10','8.1'
        if($osInfo.Version -eq '8.1')
        {
            Write-Warning "Detected not verified operating system $($osInfo.Caption)."
        }
    }
    if(-not $isSupported)
    {
        Write-Warning "Detected not supported operating system $($osInfo.Caption). Do not proceed."
    }
    $isSupported
}