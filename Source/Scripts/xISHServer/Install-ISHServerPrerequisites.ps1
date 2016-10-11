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