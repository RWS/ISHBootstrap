function Initialize-ISHLocale
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-4D619D1F-CA8C-4E43-BA0C-8CEB456AC263

    #Set the locale
    Write-Debug "Setting system locale to en-US"
    Set-WinSystemLocale en-US
    Write-Verbose "Set system locale to en-US"
}