param (
    [Parameter(Mandatory=$false)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion
)    
. $PSScriptRoot\..\..\Cmdlets\Helpers\Invoke-CommandWrap.ps1
try
{
    switch ($ISHServerVersion)
    {
        '12' {$ishServerModuleName="xISHServer.12"}
        '13' {$ishServerModuleName="xISHServer.13"}
    }
    if($Computer)
    {
        $session=New-PSSession -ComputerName $Computer
        Import-Module $ishServerModuleName -PSSession $session -Force
        Invoke-CommandWrap -Session $session -BlockName "Initialize Debug/Verbose preference on session" -ScriptBlock {}
    }
    else
    {
        Import-Module $ishServerModuleName -Force
    }

    Install-ISHWindowsFeature
    Install-ISHToolDotNET
    Install-ISHToolVisualCPP
    Install-ISHToolMSXML4
    Install-ISHToolJAVA
    Install-ISHToolJavaHelp
    Install-ISHToolHtmlHelp
    Install-ISHToolAntennaHouse
    Install-ISHToolOracleODAC

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
    Set-ISHFirewallOracle
    Set-ISHFirewallHTTPS
    if($ISHServerVersion -eq "12")
    {
        Set-ISHFirewallMSDTC
    }
}

finally
{
    Get-Module $ishServerModuleName |Remove-Module    
    if($session)
    {
        $session |Remove-PSSession
    }
}

