function Set-ISHFirewallNETBIOS
{
    $ruleNameTCP="ISH - NETBIOS - TCP"
    $ruleNameUDP="ISH - NETBIOS - UDP"
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-0522A5F7-1352-4ACD-A26E-C4EE51713B4E
    Get-NetFirewallRule -DisplayName $ruleNameTCP -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    Get-NetFirewallRule -DisplayName $ruleNameUDP -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    
    New-NetFirewallRule -DisplayName $ruleNameTCP -Direction Inbound -Action Allow -LocalPort @("139","445") -Protocol TCP |Out-Null
    New-NetFirewallRule -DisplayName $ruleNameTCP -Direction Outbound -Action Allow -LocalPort @("139","445") -Protocol TCP |Out-Null
	Write-Verbose "$ruleNameTCP firewall rule set"

    New-NetFirewallRule -DisplayName $ruleNameUDP -Direction Inbound -Action Allow -LocalPort @("137","138") -Protocol UDP |Out-Null
    New-NetFirewallRule -DisplayName $ruleNameUDP -Direction Outbound -Action Allow -LocalPort @("137","138") -Protocol UDP |Out-Null

	Write-Verbose "$ruleNameUDP firewall rule set"
}