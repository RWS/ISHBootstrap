param (
    [Parameter(Mandatory=$false)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion,
    [Parameter(Mandatory=$false)]
    [switch]$InstallOracle=$false
)    
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-MyInvocation.ps1"
Write-MyInvocation -Invocation $MyInvocation

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
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Name $ishServerModuleName
    }

    Install-ISHWindowsFeature
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

