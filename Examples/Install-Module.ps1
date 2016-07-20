if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

try
{
    $sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
    $cmdletsPaths="$sourcePath\Cmdlets"
    $scriptsPaths="$sourcePath\Scripts"

    . "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
    . "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

    $computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName"

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }

    $xISHInstallRepository=Get-ISHBootstrapperContextValue -ValuePath "xISHInstallRepository"
    $ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
    $ishServerVersion=($ishVersion -split "\.")[0]

    $ishServerRepository=Get-ISHBootstrapperContextValue -ValuePath "ISHServerRepository"
    $ishServerModuleName="ISHServer.$ishServerVersion"

    $ishDeployRepository=Get-ISHBootstrapperContextValue -ValuePath "ISHDeployRepository"
    $ishDeployModuleName="ISHDeploy.$ishVersion"

    & $scriptsPaths\PowerShellGet\Install-Module.ps1 -Computer $computerName -ModuleName @("CertificatePS","Carbon","PSFTP") -Repository PSGallery
    & $scriptsPaths\PowerShellGet\Install-Module.ps1 -Computer $computerName -ModuleName $ishServerModuleName -Repository $ishServerRepository
    & $scriptsPaths\PowerShellGet\Install-Module.ps1 -Computer $computerName -ModuleName xISHInstall -Repository $xISHInstallRepository
    & $scriptsPaths\PowerShellGet\Install-Module.ps1 -Computer $computerName -ModuleName $ishDeployModuleName -Repository $ishDeployRepository

}
finally
{
}
