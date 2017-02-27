param(
    [Parameter(Mandatory=$true,ParameterSetName="Database")]
    [ValidateSet("12.0.3","12.0.4","13.0.0")]
    [string]$ISHVersion
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

$ishServerVersion=($ISHVersion -split "\.")[0]

$packages=@{
    Name="mssqlserver2014express"
}

& $PSScriptRoot\..\Prerequisites\Install-Prerequisites.ps1 -Chocolatey $packages

Write-Separator -Invocation $MyInvocation -Footer