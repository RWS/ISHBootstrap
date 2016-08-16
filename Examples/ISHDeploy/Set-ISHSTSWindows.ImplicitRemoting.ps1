param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$true)]
    [string]$ISHVersion
)        

$ishBootStrapRootPath="C:\GitHub\ISHBootstrap"
$cmdletsPaths="$ishBootStrapRootPath\Source\Cmdlets"
$scriptsPaths="$ishBootStrapRootPath\Source\Scripts"

if(-not $Computer)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

if(-not (Get-Command Invoke-ImplicitRemoting -ErrorAction SilentlyContinue))
{
    . $cmdletsPaths\Helpers\Invoke-ImplicitRemoting.ps1
}  

$installIISWinAuthBlock= {
    Install-ISHWindowsFeatureIISWinAuth
}
$setWindowsBlock= {
    Set-ISHSTSConfiguration -ISHDeployment $DeploymentName -AuthenticationType Windows
}



#Install the packages
try
{
    $ishServerVersion=($ishVersion -split "\.")[0]
    $ishServerModuleName="xISHServer.$ishServerVersion"
    $ishDelpoyModuleName="ISHDeploy.$ishVersion"
    Invoke-ImplicitRemoting -ScriptBlock $installIISWinAuthBlock -BlockName "Install IIS Windows Authentication" -ComputerName $Computer -ImportModule $ishServerModuleName
    Invoke-ImplicitRemoting -ScriptBlock $setWindowsBlock -BlockName "Windows Authentication $DeploymentName" -ComputerName $Computer -ImportModule $ishDelpoyModuleName
}
finally
{

}
