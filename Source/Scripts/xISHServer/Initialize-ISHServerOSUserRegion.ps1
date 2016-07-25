param (
    [Parameter(Mandatory=$true)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$true)]
    [PSCredential]$OSUserCredential,
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
    $session=New-PSSession -ComputerName $Computer -Credential $OSUserCredential
    Import-Module $ishServerModuleName -PSSession $session -Force
    Invoke-CommandWrap -Session $session -BlockName "Initialize Debug/Verbose preference on session" -ScriptBlock {}

    Initialize-ISHRegional
}

finally
{
    Get-Module $ishServerModuleName |Remove-Module    
    if($session)
    {
        $session |Remove-PSSession
    }
}

