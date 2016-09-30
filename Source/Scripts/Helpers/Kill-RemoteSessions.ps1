param (
    [Parameter(Mandatory=$true)]
    [string[]]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null
) 

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$killRemoteSessionsScriptBlock={
    Write-Host "Killing all wsmprovhost.exe processes"
    & taskkill /im:wsmprovhost.exe /f |Out-Null
}

Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $killRemoteSessionsScriptBlock -BlockName "Kill remote sessions"
Write-Separator -Invocation $MyInvocation -Footer