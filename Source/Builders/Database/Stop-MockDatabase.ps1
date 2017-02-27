param(
    
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

Write-Information "Stopping SQL Server services"
Get-Service *SQL*|Stop-Service -Force

Write-Separator -Invocation $MyInvocation -Footer