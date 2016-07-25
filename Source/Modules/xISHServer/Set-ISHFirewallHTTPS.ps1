function Set-ISHFirewallHTTPS
{
    $ruleNameTCP="ISH - HTTPS - TCP"
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-DF212CD1-5618-44BF-9AF8-F1B76FCC485D
    Get-NetFirewallRule -DisplayName $ruleNameTCP -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    
    New-NetFirewallRule -DisplayName $ruleNameTCP -Direction Inbound -Action Allow -LocalPort @("80","443") -Protocol TCP |Out-Null
    New-NetFirewallRule -DisplayName $ruleNameTCP -Direction Outbound -Action Allow -LocalPort @("80","443") -Protocol TCP |Out-Null

	Write-Verbose "$ruleNameTCP firewall rule set"
}