function Initialize-ISHMSDTCSettings
{
    Write-Debug "Setting DTC Settings"

    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC -Name AllowOnlySecureRpcCalls -Value 0 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC -Name TurnOffRpcSecurity -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name NetworkDtcAccess -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name XaTransactions -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name NetworkDtcAccessTransactions -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name NetworkDtcAccessOutbound -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name NetworkDtcAccessInbound -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name LuTransactions -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name LuTransactions -Value 1 -Type DWord

    Write-Verbose "Set MSDTC Settings"

}