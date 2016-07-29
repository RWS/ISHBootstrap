param (
    [Parameter(Mandatory=$true)]
    [string]$Computer,
    [Parameter(Mandatory=$true)]
    [PSCredential]$OSUserCredential,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion
)    
. $PSScriptRoot\..\..\Cmdlets\Helpers\Invoke-CommandWrap.ps1
try
{
    $ishServerModuleName="xISHServer.$ISHServerVersion"
    $session=New-PSSession -ComputerName $Computer -Credential $OSUserCredential
    Import-Module $ishServerModuleName -PSSession $session -Force
    Invoke-CommandWrap -Session $session -BlockName "Initialize Debug/Verbose preference on session" -ScriptBlock {}

    Initialize-ISHRegional
}

finally
{
    if($session)
    {
        $session |Remove-PSSession
    }
}

