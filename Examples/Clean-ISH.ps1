if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
$credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke
$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
$ishServerVersion=($ishVersion -split "\.")[0]

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$cleanBlock= {
    $infoSharePath="C:\InfoShare"
    Write-Debug "infoSharePath=$infoSharePath"

    $ishDeployProgramDataPath=Join-Path "C:\ProgramData" "ISHDeploy.$ishVersion"
    Write-Debug "ishDeployProgramDataPath=$ishDeployProgramDataPath"

    $ishServerProgramDataPath=Join-Path "C:\ProgramData" "xISHServer.$ishServerVersion"
    Write-Debug "ishServerProgramDataPath=$ishServerProgramDataPath"

    $ishDeployModuleName="ISHDeploy.$ishVersion"
    Write-Debug "ishDeployModuleName=$ishDeployModuleName"
    $ishServerModuleName="xISHServer.$ishServerVersion"
    Write-Debug "ishServerModuleName=$ishServerModuleName"
    $ishAutomationModuleName="xISHServer.$ishServerVersion"
    Write-Debug "ishServerModuleName=$ishServerModuleName"

    Uninstall-Module $ishDeployModuleName -Force
    Write-Host "Uninstalled $ishDeployModuleName"
    Remove-Item $ishDeployProgramDataPath -Recurse -Force
    Write-Host "Removed $ishDeployProgramDataPath"

    Uninstall-Module $ishServerModuleName -Force
    Write-Host "Uninstalled $ishServerModuleName"
    Remove-Item $ishServerProgramDataPath -Recurse -Force
    Write-Host "Removed $ishServerProgramDataPath"

    Uninstall-Module xISHInstall -Force
    Write-Host "Uninstalled xISHInstall"
    
    Remove-Item $infoSharePath -Recurse -Force
    Write-Host "Removed $infoSharePath"

}

try
{

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }
    Invoke-CommandWrap -ComputerName $computerName -Credential $credential -ScriptBlock $cleanBlock -BlockName "Clean ISH" -UseParameters @("ishVersion","ishServerVersion")

}
finally
{
}
