<#PSScriptInfo
.DESCRIPTION PowerShell module for ISHBootstrap
.VERSION 0.1
#>

New-Variable -Name ISHDeployemntConfigFile -Value "$env:ProgramData\ISHBootstrap\config-docs-project.json" -Scope Script -Force

$public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Exclude @("*NotReady*","*.Tests.ps1"))
$private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Exclude @("*NotReady*","*.Tests.ps1"))

Foreach($import in @($public + $private))
{
    . $import.FullName
}

Export-ModuleMember -Function $public.BaseName