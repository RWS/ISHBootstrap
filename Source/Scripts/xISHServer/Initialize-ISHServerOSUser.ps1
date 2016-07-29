param (
    [Parameter(Mandatory=$true,ParameterSetName="Remote")]
    [string]$Computer,
    [Parameter(Mandatory=$true,ParameterSetName="Remote")]
    [PSCredential]$CrentialForCredSSP,
    [Parameter(Mandatory=$true,ParameterSetName="Local")]
    [Parameter(ParameterSetName="Remote")]
    [string]$OSUser,
    [Parameter(Mandatory=$true,ParameterSetName="Local")]
    [Parameter(ParameterSetName="Remote")]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion
)    
. $PSScriptRoot\..\..\Cmdlets\Helpers\Invoke-CommandWrap.ps1
try
{
    $ishServerModuleName="xISHServer.$ISHServerVersion"
    if($Computer)
    {
        $session=New-PSSession -ComputerName $Computer -Credential $CrentialForCredSSP -UseSSL -Authentication Credssp
        Import-Module $ishServerModuleName -PSSession $session -Force
        Invoke-CommandWrap -Session $session -BlockName "Initialize Debug/Verbose preference on session" -ScriptBlock {}
    }
    else
    {
        Import-Module $ishServerModuleName -Force
    }

    Initialize-ISHUser -OSUser $OSUser
}

finally
{
    if($session)
    {
        $session |Remove-PSSession
    }
}

