#Requires -runasadministrator

#region Helpers
. $PSScriptRoot\Get-ISHOSInfo.ps1
. $PSScriptRoot\Get-ISHNETInfo.ps1
. $PSScriptRoot\Test-ISHServerCompliance.ps1
. $PSScriptRoot\Get-ISHServerFolderPath.ps1
. $PSScriptRoot\Grant-ISHUserLogOnAsService.ps1
. $PSScriptRoot\Get-ISHCOMPlus.ps1
#endregion

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
. $PSScriptRoot\Get-ISHPrerequisites.ISH13.ps1
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
. $PSScriptRoot\Install-ISHWindowsFeatureIISWinAuth.ps1
. $PSScriptRoot\Install-ISHVisualBasicRuntime.ps1
#endregion

#region Regional settings
. $PSScriptRoot\Initialize-ISHRegional.ps1
. $PSScriptRoot\Initialize-ISHRegionalDefault.ps1
#endregion

#region License
. $PSScriptRoot\Set-ISHToolAntennaHouseLicense.ps1
#endregion