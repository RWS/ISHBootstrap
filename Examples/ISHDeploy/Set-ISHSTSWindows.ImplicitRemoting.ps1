param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$true)]
    [string]$ISHVersion
)        
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
        $ishServerVersion=($ISHVersion -split "\.")[0]
        $ishServerModuleName="xISHServer.$ishServerVersion"
        $ishDelpoyModuleName="ISHDeploy.$ISHVersion"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Name @($ishServerModuleName,$ishDelpoyModuleName)
    }

    Install-ISHWindowsFeatureIISWinAuth
    Set-ISHSTSConfiguration -ISHDeployment $DeploymentName -AuthenticationType Windows
}
finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
}