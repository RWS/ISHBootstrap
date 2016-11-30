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

param (
    [Parameter(Mandatory=$false)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion,
    [Parameter(Mandatory=$false)]
    [switch]$InstallOracle=$false
)    
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

if($Computer)
{
    . $cmdletsPaths\Helpers\Add-ModuleFromRemote.ps1
    . $cmdletsPaths\Helpers\Remove-ModuleFromRemote.ps1
}

try
{
    if($Computer)
    {
        $ishServerModuleName="xISHServer.$ISHServerVersion"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Credential $Credential -Name $ishServerModuleName
    }
    $osInfo=Get-ISHOSInfo

    Install-ISHWindowsFeature
    if($osInfo.IsCore)
    {
        Install-ISHVisualBasicRuntime
    }
    Install-ISHToolDotNET
    Install-ISHToolVisualCPP
    Install-ISHToolMSXML4
    Install-ISHToolJAVA
    Install-ISHToolJavaHelp
    Install-ISHToolHtmlHelp
    Install-ISHToolAntennaHouse
    if($InstallOracle)
    {
        Install-ISHToolOracleODAC
    }

    Initialize-ISHLocale
    Initialize-ISHIIS
    Initialize-ISHRegionalDefault

    if($ISHServerVersion -eq "12")
    {
        Initialize-ISHMSDTCTransactionTimeout
        Initialize-ISHMSDTCSettings
    }

    Set-ISHFirewallNETBIOS
    Set-ISHFirewallSMTP
    Set-ISHFirewallSQLServer
    if($InstallOracle)
    {
        Set-ISHFirewallOracle
    }
    Set-ISHFirewallHTTPS
    if($ISHServerVersion -eq "12")
    {
        Set-ISHFirewallMSDTC
    }
}

finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
}

Write-Separator -Invocation $MyInvocation -Footer
