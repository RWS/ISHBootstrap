param (
    [Parameter(Mandatory=$false)]
    [string]$Computer,
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



$getStatusBlock= {
    Write-Host "History"
    Get-ISHDeploymentHistory -ISHDeployment $DeploymentName
    Write-Host "Changed parameters"
    Get-ISHDeploymentParameters -ISHDeployment $DeploymentName -Changed | Format-Table
}


try
{
    $ishDelpoyModuleName="ISHDeploy.$ishVersion"
    Invoke-ImplicitRemoting -ScriptBlock $getStatusBlock -BlockName "Status on $DeploymentName" -ComputerName $Computer -ImportModule $ishDelpoyModuleName
}
finally
{

}
