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
    [ValidateSet("12","13","14")]
    [string]$ISHServerVersion,
    [Parameter(Mandatory=$false)]
    [switch]$InstallOracle=$false,
    [Parameter(Mandatory=$false)]
    [switch]$InstallMSXML4=$false
)    
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

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
        $ishServerModuleName="ISHServer.$ISHServerVersion"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Credential $Credential -Name $ishServerModuleName
    }
    $osInfo=Get-ISHOSInfo

    Write-Progress @scriptProgress -Status "Installing windows features"
    Install-ISHWindowsFeature
    if($osInfo.IsCore)
    {
        Install-ISHVisualBasicRuntime
    }
    Write-Progress @scriptProgress -Status "Installing packages"
    Install-ISHToolDotNET
    Install-ISHToolVisualCPP
    if(($ISHServerVersion -eq "12") -and ($InstallMSXML4))
    {
        Install-ISHToolMSXML4
    }
    if($ISHServerVersion -eq "14")
    {
        Install-ISHToolAdoptOpenJRE
        Install-ISHToolAdoptOpenJDK
    }
    else
    {
        Install-ISHToolJAVA
    }
    Install-ISHToolJavaHelp
    Install-ISHToolHtmlHelp
    Install-ISHToolAntennaHouse
    if($InstallOracle)
    {
        Install-ISHToolOracleODAC
    }
    if($ISHServerVersion -eq "15")
    {
        Install-ISHDotNetHosting 
    }
    Write-Progress @scriptProgress -Status "Initializing"
    Initialize-ISHLocale
    Initialize-ISHIIS
    Initialize-ISHRegionalDefault

    if($ISHServerVersion -eq "12")
    {
        Initialize-ISHMSDTCTransactionTimeout
        Initialize-ISHMSDTCSettings
    }

    if((Get-Service -Name MpsSvc).Status -eq "Running")
    {
        Write-Progress @scriptProgress -Status "Configuring firewall"
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
    else
    {
        Write-Warning "Windows Firewall service is not running"
    }

    Initialize-ISHRegistry
}

finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
