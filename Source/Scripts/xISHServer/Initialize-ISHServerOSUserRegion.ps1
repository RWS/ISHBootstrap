param (
    [Parameter(Mandatory=$true)]
    [string]$Computer,
    [Parameter(Mandatory=$true)]
    [PSCredential]$OSUserCredential,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion
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
        $session=New-PSSession -ComputerName $Computer -Credential $OSUserCredential
        $remote=Add-ModuleFromRemote -Session $session -Name $ishServerModuleName
    }

    Initialize-ISHRegional
}

finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
        $session|Remove-PSSession
    }
}

Write-Separator -Invocation $MyInvocation -Footer