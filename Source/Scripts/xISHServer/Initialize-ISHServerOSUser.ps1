param (
    [Parameter(Mandatory=$true,ParameterSetName="Remote")]
    [string]$Computer,
    [Parameter(Mandatory=$true,ParameterSetName="Remote")]
    [PSCredential]$CrentialForCredSSP,
    [Parameter(Mandatory=$true,ParameterSetName="Loacal,Remote")]
    [string]$OSUser,
    [Parameter(Mandatory=$true,ParameterSetName="Loacal,Remote")]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion
)    
. $PSScriptRoot\..\..\Cmdlets\Helpers\Invoke-CommandWrap.ps1
try
{
    if($Computer)
    {
        $session=New-PSSession -ComputerName $Computer -Credential $CrentialForCredSSP -UseSSL -Authentication Credssp
    }

    $block={
        Initialize-ISHUser -OSUser $OSUser
    }
    Invoke-CommandWrap -Session $session -BlockName "Initialize $OSUser" -ScriptBlock $block -UseParameters @("OSUser")
}

finally
{
    if($session)
    {
        $session |Remove-PSSession
    }
}

