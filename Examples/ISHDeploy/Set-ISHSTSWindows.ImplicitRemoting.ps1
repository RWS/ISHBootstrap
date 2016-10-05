param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$true)]
    [string]$ISHVersion
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
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Credential $Credential -Name @($ishServerModuleName,$ishDelpoyModuleName)
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

Write-Separator -Invocation $MyInvocation -Footer -Name "Configure"