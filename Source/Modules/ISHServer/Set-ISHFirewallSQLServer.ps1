function Set-ISHFirewallSQLServer
{
    $ruleNameTCP="ISH - SQLServer - TCP"
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-A2B497E3-9D50-4DE0-88B5-81A9ECA90471
    Get-NetFirewallRule -DisplayName $ruleNameTCP -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    
    New-NetFirewallRule -DisplayName $ruleNameTCP -Direction Inbound -Action Allow -LocalPort @("1433") -Protocol TCP |Out-Null
    New-NetFirewallRule -DisplayName $ruleNameTCP -Direction Outbound -Action Allow -LocalPort @("1433") -Protocol TCP |Out-Null
	
	Write-Verbose "$ruleNameTCP firewall rule set"
}