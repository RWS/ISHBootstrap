param (
    [Parameter(Mandatory=$true,ParameterSetName="Remote")]
    [string]$Computer,
    [Parameter(Mandatory=$false,ParameterSetName="Remote")]
    $SessionOptions=$null,
    [Parameter(Mandatory=$true,ParameterSetName="Remote")]
    [PSCredential]$Credential,
    [Parameter(Mandatory=$false,ParameterSetName="Remote")]
    [switch]$CredSSP,
    [Parameter(Mandatory=$true,ParameterSetName="Local")]
    [Parameter(ParameterSetName="Remote")]
    [string]$OSUser,
    [Parameter(Mandatory=$true,ParameterSetName="Local")]
    [Parameter(ParameterSetName="Remote")]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion
)    
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

. $cmdletsPaths\Helpers\Add-ModuleFromRemote.ps1
. $cmdletsPaths\Helpers\Remove-ModuleFromRemote.ps1

try
{
    if($Computer)
    {
        $ishServerModuleName="xISHServer.$ISHServerVersion"
        if($CredSSP)
        {
            if($SessionOptions)
            {
                $session=New-PSSession -ComputerName $Computer -Credential $Credential -UseSSL -Authentication Credssp –SessionOption $SessionOptions
            }
            else
            {
                $session=New-PSSession -ComputerName $Computer -Credential $Credential -UseSSL -Authentication Credssp
            }
        }
        else
        {
            $session=New-PSSession -ComputerName $Computer -Credential $Credential
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

Write-Separator -Invocation $MyInvocation -Footer