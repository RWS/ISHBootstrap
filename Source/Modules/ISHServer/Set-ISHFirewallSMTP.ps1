function Set-ISHFirewallSMTP
{
    $ruleNameTCP="ISH - SMTP - TCP"

    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-A9B92E3C-1005-419C-A191-58E476C6FE5A
    Get-NetFirewallRule -DisplayName $ruleNameTCP -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    
    New-NetFirewallRule -DisplayName $ruleNameTCP -Direction Inbound -Action Allow -LocalPort @("25") -Protocol TCP |Out-Null
    New-NetFirewallRule -DisplayName $ruleNameTCP -Direction Outbound -Action Allow -LocalPort @("25") -Protocol TCP |Out-Null

	Write-Verbose "$ruleNameTCP firewall rule set"
}
