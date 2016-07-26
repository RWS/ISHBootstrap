function Set-ISHFirewallMSDTC
{
    $ruleNameTCP="ISH - MSDTC - TCP"
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-D7592291-94D3-4BBF-9034-1988F4405040
	
    Get-NetFirewallRule -DisplayName $ruleNameTCP -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    
    New-NetFirewallRule -DisplayName $ruleNameTCP -Direction Inbound -Action Allow -LocalPort @("135","5000-6000") -Protocol TCP |Out-Null
    New-NetFirewallRule -DisplayName $ruleNameTCP -Direction Outbound -Action Allow -LocalPort @("135","5000-6000") -Protocol TCP |Out-Null
	Write-Verbose "$ruleNameTCP firewall rule set"
}