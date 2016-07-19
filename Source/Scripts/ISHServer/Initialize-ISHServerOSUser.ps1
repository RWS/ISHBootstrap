param (
    [Parameter(Mandatory=$true,ParameterSetName="Remote")]
    [string]$Computer=$null,
    [Parameter(Mandatory=$true,ParameterSetName="Remote")]
    [PSCredential]$CrentialForCredSSP,
    [Parameter(Mandatory=$true)]
    [string]$OSUser,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion
)    
. $PSScriptRoot\..\..\Cmdlets\Helpers\Invoke-CommandWrap.ps1
try
{
#    switch ($ISHServerVersion)
#    {
#        '12' {$ishServerModuleName="ISHServer.12"}
#        '13' {$ishServerModuleName="ISHServer.13"}
#    }
    if($Computer)
    {
        $session=New-PSSession -ComputerName $Computer -Credential $CrentialForCredSSP -UseSSL -Authentication Credssp
#        Import-Module $ishServerModuleName -PSSession $session -Force
#        Invoke-CommandWrap -Session $session -BlockName "Initialize Debug/Verbose preference on session" -ScriptBlock {}
    }
    else
    {
#        Import-Module $ishServerModuleName -Force
    }
    $block={
        Initialize-ISHUser -OSUser $OSUser
    }
    Invoke-CommandWrap -Session $session -BlockName "Initialize $OSUser" -ScriptBlock $block -UseParameters @("OSUser")
}

finally
{
#    Get-Module $ishServerModuleName |Remove-Module    
    if($session)
    {
        $session |Remove-PSSession
    }
}

