<#
# Copyright (c) 2014 All Rights Reserved by the SDL Group.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#>

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
