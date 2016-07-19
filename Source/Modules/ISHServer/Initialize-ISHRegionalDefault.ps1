function Initialize-ISHRegionalDefault
{
    # Suggested by Jered Bastinck <jbastinck@sdl.com>; Koen De Wit <kdewit@sdl.com>
    
    Write-Debug "Creating new registry drive for HKEY_USERS"
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS |Out-Null
    Write-Verbose "Created new registry drive for HKEY_USERS"

    # Set the regional settings
    Write-Debug "Setting Formatters for DEFAULT account"
    Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\International" -Name sShortDate -Value "dd/MM/yyyy"
    Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\International" -Name sLongDate -Value "ddddd d MMMM yyyy"
    Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\International" -Name sShortTime -Value "HH:mm:ss"
    Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\International" -Name sLongTime -Value "HH:mm:ss"
    Write-Verbose "Set Formatters  for DEFAULT account"
}