function Get-ISHOSInfo
{
    $caption=(Get-CimInstance Win32_OperatingSystem).Caption
    $regex="Microsoft Windows (?<Server>(Server) )?((?<Version>[0-9]+( R[0-9]?)?) )?(?<Type>.+)"
    $null=$caption -match $regex
    $hash=@{
        IsServer=$Matches["Server"] -ne $null
        Version=$Matches["Version"]
        Type=$Matches["Type"]
        Caption=$caption
    }
    New-Object -TypeName psobject -Property $hash    
}