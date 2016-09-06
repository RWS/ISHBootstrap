param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceLocation,
    [Parameter(Mandatory=$false)]
    [string]$PublishLocation=$null,
    [Parameter(Mandatory=$false)]
    [ValidateSet("Trusted","Untrusted")]
    [string]$InstallationPolicy="Trusted"
)        

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$registerPSRepositoryBlock = {
    Write-Debug "Name=$Name"
    Write-Debug "SourceLocation=$SourceLocation"
    Write-Debug "PublishLocation=$PublishLocation"
    Write-Debug "InstallationPolicy=$InstallationPolicy"
    
    Write-Debug "Unregistering repository $Name"
    Unregister-PSRepository -Name $Name -ErrorAction SilentlyContinue | Out-Null
    Write-Debug "Registering repository $Name"
    if($PublishLocation)
    {
        Register-PSRepository -Name $Name -SourceLocation $SourceLocation -PublishLocation  $PublishLocation -InstallationPolicy $InstallationPolicy | Out-Null
    }
    else
    {
        Register-PSRepository -Name $Name -SourceLocation $SourceLocation -InstallationPolicy $InstallationPolicy | Out-Null
    }
}


try
{
    Invoke-CommandWrap -ComputerName $Computer -ScriptBlock $registerPSRepositoryBlock -BlockName "Register Repository $Name" -UseParameters @("Name","SourceLocation","PublishLocation","InstallationPolicy")
}
catch
{
    Write-Error $_
}

Write-Separator -Invocation $MyInvocation -Footer