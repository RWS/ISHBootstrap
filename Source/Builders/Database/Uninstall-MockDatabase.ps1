param(
    
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

$blockName="Uninstalling SQLServerExpress"
Write-Progress @scriptProgress -Status $blockName
Write-Information $blockName

& choco uninstall mssqlserver2014express -y

Write-Separator -Invocation $MyInvocation -Footer