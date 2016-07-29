param (
    [Parameter(Mandatory=$true)]
    [string]$Computer,
    [Parameter(Mandatory=$true)]
    [PSCredential]$OSUserCredential
)    
. $PSScriptRoot\..\..\Cmdlets\Helpers\Invoke-CommandWrap.ps1
try
{
    $session=New-PSSession -ComputerName $Computer -Credential $OSUserCredential
    $block={
        Initialize-ISHRegional
    }
    Invoke-CommandWrap -Session $session -BlockName "Initialize $OSUser" -ScriptBlock $block

}

finally
{
    if($session)
    {
        $session |Remove-PSSession
    }
}

