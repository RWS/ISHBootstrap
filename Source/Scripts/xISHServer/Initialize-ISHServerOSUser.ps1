param (
    [Parameter(Mandatory=$true,ParameterSetName="Remote")]
    [string]$Computer,
    [Parameter(Mandatory=$false,ParameterSetName="Remote")]
    $SessionOptions=$null,
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
. $PSScriptRoot\..\..\Cmdlets\Helpers\Add-ModuleFromRemote.ps1
. $PSScriptRoot\..\..\Cmdlets\Helpers\Remove-ModuleFromRemote.ps1

try
{
    if($Computer)
    {
        $ishServerModuleName="xISHServer.$ISHServerVersion"
        if($SessionOptions)
        {
            $session=New-PSSession -ComputerName $Computer -Credential $CrentialForCredSSP -UseSSL -Authentication Credssp –SessionOption $SessionOptions
        }
        else
        {
            $session=New-PSSession -ComputerName $Computer -Credential $CrentialForCredSSP -UseSSL -Authentication Credssp
        }
        $remote=Add-ModuleFromRemote -Session $session -Name $ishServerModuleName
    }

    Initialize-ISHUser -OSUser $OSUser
}

finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
    if($session)
    {
        $session |Remove-PSSession
    }
}

