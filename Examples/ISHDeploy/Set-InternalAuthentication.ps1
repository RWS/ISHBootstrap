﻿param (
    [Parameter(Mandatory=$false)]
    [string]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName
)
$ishBootStrapRootPath=Resolve-Path "$PSScriptRoot\..\.."
$cmdletsPaths="$ishBootStrapRootPath\Source\Cmdlets"
$scriptsPaths="$ishBootStrapRootPath\Source\Scripts"

. $ishBootStrapRootPath\Examples\ISHDeploy\Cmdlets\Write-Separator.ps1
Write-Separator -Invocation $MyInvocation -Header -Name "Configure"

if(-not $Computer)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

if(-not (Get-Command Invoke-CommandWrap -ErrorAction SilentlyContinue))
{
    . $cmdletsPaths\Helpers\Invoke-CommandWrap.ps1
}        

$internalAuthenticationScriptBlock= {
    Enable-ISHIntegrationSTSInternalAuthentication -ISHDeployment $DeploymentName
    Write-Host "Internal authentication enabled"
}


#Install the packages
try
{
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $internalAuthenticationScriptBlock -BlockName "Enable internal authentication on $DeploymentName" -UseParameters @("DeploymentName")
}
finally
{

}

Write-Separator -Invocation $MyInvocation -Footer -Name "Configure"