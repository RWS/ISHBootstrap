param (
    [Parameter(Mandatory=$true)]
    [string[]]$Computer
) 

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-MyInvocation.ps1"
Write-MyInvocation -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$killRemoteSessionsScriptBlock={
    Write-Host "Killing all wsmprovhost.exe processes"
    & taskkill /im:wsmprovhost.exe /f |Out-Null
}

Invoke-CommandWrap -ComputerName $Computer -ScriptBlock $killRemoteSessionsScriptBlock -BlockName "Kill remote sessions"