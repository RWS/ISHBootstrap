param (
    [Parameter(Mandatory=$false)]
    [string]$Computer,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$true)]
    [string]$ISHVersion    
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
else
{
   . $cmdletsPaths\Helpers\Add-ModuleFromRemote.ps1
   . $cmdletsPaths\Helpers\Remove-ModuleFromRemote.ps1
}

try
{
    if($Computer)
    {
        $ishDelpoyModuleName="ISHDeploy.$ISHVersion"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Name $ishDelpoyModuleName
    }

    Undo-ISHDeployment -ISHDeployment $DeploymentName
    Clear-ISHDeploymentHistory -ISHDeployment $DeploymentName
}
finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
}

Write-Separator -Invocation $MyInvocation -Footer