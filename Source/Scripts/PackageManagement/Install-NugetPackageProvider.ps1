﻿param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer
)        

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$installProviderScriptBlock={
    Write-Verbose "Installing/Updating PackageProvider NuGet"
    Install-PackageProvider -Name NuGet -Force| Out-Null
    Write-Host "Installed/Updated PackageProvider NuGet"
}

#Install the packages
try
{
    Invoke-CommandWrap -ComputerName $Computer -ScriptBlock $installProviderScriptBlock -BlockName "Nuget package provider"
}
catch
{
    Write-Error $_
}

Write-Separator -Invocation $MyInvocation -Footer