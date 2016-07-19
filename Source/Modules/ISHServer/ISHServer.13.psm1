. $PSScriptRoot\Get-ISHServerFolderPath.ps1

#region Ports
. $PSScriptRoot\Set-ISHFirewallHTTPS.ps1
. $PSScriptRoot\Set-ISHFirewallNETBIOS.ps1
. $PSScriptRoot\Set-ISHFirewallOracle.ps1
. $PSScriptRoot\Set-ISHFirewallHTTPS.ps1
. $PSScriptRoot\Set-ISHFirewallSMTP.ps1
. $PSScriptRoot\Set-ISHFirewallSQLServer.ps1
#endregion


#region Global
. $PSScriptRoot\Get-ISHServerFolderPath.ps1
. $PSScriptRoot\Initialize-ISHLocale.ps1
. $PSScriptRoot\Initialize-ISHIIS.ps1
. $PSScriptRoot\Initialize-ISHUser.ps1
#endregion

#region Install
. $PSScriptRoot\Install-ISHToolMSXML4.ps1
. $PSScriptRoot\Install-ISHToolDotNET.ISH13.ps1
. $PSScriptRoot\Install-ISHToolVisualCPP.ISH13.ps1
. $PSScriptRoot\Install-ISHToolJAVA.ps1
. $PSScriptRoot\Install-ISHToolJavaHelp.ps1
. $PSScriptRoot\Install-ISHToolHtmlHelp.ps1
. $PSScriptRoot\Install-ISHToolAntennaHouse.ps1
. $PSScriptRoot\Install-ISHToolOracleODAC.ps1
. $PSScriptRoot\Install-ISHWindowsFeature.ps1
#endregion

#region Regional settings
. $PSScriptRoot\Initialize-ISHRegional.ps1
. $PSScriptRoot\Initialize-ISHRegionalDefault.ps1
#endregion

<#
$exportedCmdLetName=@(
    "Get-ISHServerFolderPath"

#region Ports
    "Set-ISHFirewallHTTPS"
    "Set-ISHFirewallNETBIOS"
    "Set-ISHFirewallOracle"
    "Set-ISHFirewallHTTPS"
    "Set-ISHFirewallSMTP"
    "Set-ISHFirewallSQLServer"
#endregion

#region Global
    "Get-ISHServerFolderPath"
    "Initialize-ISHLocale"
    "Initialize-ISHIIS"
    "Initialize-ISHUser"
#endregion

#region Install
    "Install-ISHToolMSXML4"
    "Install-ISHToolDotNET"
    "Install-ISHToolVisualCPP"
    "Install-ISHToolJAVA"
    "Install-ISHToolJavaHelp"
    "Install-ISHToolHtmlHelp"
    "Install-ISHToolAntennaHouse"
    "Install-ISHToolOracleODAC"
    "Install-ISHWindowsFeature"
#endregion

#region Regional settings
    "Initialize-ISHRegional"
    "Initialize-ISHRegionalDefault"
#endregion
)

$exportedCmdLetName|Export-ModuleMember -Cmdlet $_

#>