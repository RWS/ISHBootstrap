function Initialize-ISHUser
{
    param (
        [Parameter(Mandatory=$true)]
        [string]$OSUser
    )
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-4D619D1F-CA8C-4E43-BA0C-8CEB456AC263

    # Add the osuser to the administrators group
    Write-Debug "Adding $OSUser to Administrators"
    Add-GroupMember -Name Administrators -Member $OSUser
    Write-Verbose "Added $OSUser to Administrators"
    
    # Grant Log on as Service to the osuser
    Write-Debug "Granting ServiceLogonRight to $OSUser"
    Grant-Privilege -Identity $OSUser -Privilege "SeServiceLogonRight"
    Write-Verbose "Granted ServiceLogonRight to $OSUser"

    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-70BAEF73-D2B4-488B-8F71-505DB8ACB244
    Write-Debug "Disabling Force Unload of registry"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name DisableForceUnload -Value $true
    Write-Verbose "Disabled Force Unload of registry"
}