param (
    [Parameter(Mandatory=$false)]
    [string]$Computer,
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

try
{
    $undoBlock={
        $deployment = Get-ISHDeployment -Name $DeploymentName
        Undo-ISHDeployment -ISHDeployment $DeploymentName
        Clear-ISHDeploymentHistory -ISHDeployment $DeploymentName
    }
    Invoke-CommandWrap -ComputerName $Computer -ScriptBlock $undoBlock -BlockName "Undo deployment $deploymentName" -UseParameters @("DeploymentName")
}
finally
{
}

Write-Separator -Invocation $MyInvocation -Footer -Name "Configure"