param (
    [Parameter(Mandatory=$false)]
    [string]$Computer,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName
)
. $PSScriptRoot\Cmdlets\Write-Separator.ps1
Write-Separator -Invocation $MyInvocation -Header

$ishBootStrapRootPath=Resolve-Path "$PSScriptRoot\..\.."
$cmdletsPaths="$ishBootStrapRootPath\Source\Cmdlets"
$scriptsPaths="$ishBootStrapRootPath\Source\Scripts"

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

Write-Separator -Invocation $MyInvocation -Footer