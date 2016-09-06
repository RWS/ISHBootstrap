param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
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


$installIISWinAuthBlock= {
    Install-ISHWindowsFeatureIISWinAuth
}
$setWindowsBlock= {
    Set-ISHSTSConfiguration -ISHDeployment $DeploymentName -AuthenticationType Windows
}


try
{
    Invoke-CommandWrap -ComputerName $Computer -ScriptBlock $installIISWinAuthBlock -BlockName "Install IIS Windows Authentication"
    Invoke-CommandWrap -ComputerName $Computer -ScriptBlock $setWindowsBlock -BlockName "Windows Authentication $DeploymentName" -UseParameters @("DeploymentName")
}
finally
{

}

Write-Separator -Invocation $MyInvocation -Footer -Name "Configure"