function Initialize-ISHUser
{
    param (
        [Parameter(Mandatory=$true)]
        [string]$OSUser
    )
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-4D619D1F-CA8C-4E43-BA0C-8CEB456AC263

    # Add the osuser to the administrators group
    Write-Debug "Adding $OSUser to Administrators"

    if(Get-Module "Microsoft.PowerShell.LocalAccounts" -ListAvailable)
    {
        # https://technet.microsoft.com/en-us/library/mt651690.aspx
        if(-not (Get-LocalGroupMember -Name Administrators -Member $OSUser))
        {
            Add-LocalGroupMember -Group "Administrators" -Member $OSUser
        }
    }
    else
    {
        if((& net localgroup Administrators) -notcontains $OSUser)
        {
            $netCmdArgs=@(
                "localgroup"
                "Administrators"
                $OSUser
                "/add"
            )
            & net $netCmdArgs
        }
    }

    Write-Verbose "Added $OSUser to Administrators"
    
    # Grant Log on as Service to the osuser
    Write-Debug "Granting ServiceLogonRight to $OSUser"
    Grant-ISHUserLogOnAsService -User $OSUser
    Write-Verbose "Granted ServiceLogonRight to $OSUser"

    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-70BAEF73-D2B4-488B-8F71-505DB8ACB244
    Write-Debug "Disabling Force Unload of registry"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name DisableForceUnload -Value $true
    Write-Verbose "Disabled Force Unload of registry"
}