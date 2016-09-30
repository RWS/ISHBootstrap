if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

try
{
    $sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
    $cmdletsPaths="$sourcePath\Cmdlets"
    $scriptsPaths="$sourcePath\Scripts"
    $modulesPaths="$sourcePath\Modules"

    . "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
    . "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

    $computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
    $credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }

    $ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
    $ishServerVersion=($ishVersion -split "\.")[0]

    $ishServerModuleName="xISHServer.$ishServerVersion"

    $ishDeployRepository=Get-ISHBootstrapperContextValue -ValuePath "ISHDeployRepository"
    $ishDeployModuleName="ISHDeploy.$ishVersion"

    & $scriptsPaths\PowerShellGet\Install-Module.ps1 -Computer $computerName -Credential $credential -ModuleName "Carbon" -Repository PSGallery -AllowClobber
    & $scriptsPaths\PowerShellGet\Install-Module.ps1 -Computer $computerName -Credential $credential -ModuleName @("CertificatePS","PSFTP") -Repository PSGallery
    & $scriptsPaths\PowerShellGet\Install-Module.ps1 -Computer $computerName -Credential $credential -ModuleName $ishDeployModuleName -Repository $ishDeployRepository

    if($computerName)
    {
        $ishServerRepository=Get-ISHBootstrapperContextValue -ValuePath "xISHServerRepository"
        $xISHInstallRepository=Get-ISHBootstrapperContextValue -ValuePath "xISHInstallRepository"
    
        & $scriptsPaths\PowerShellGet\Install-Module.ps1 -Computer $computerName -Credential $credential -ModuleName $ishServerModuleName -Repository $ishServerRepository
        & $scriptsPaths\PowerShellGet\Install-Module.ps1 -Computer $computerName -Credential $credential -ModuleName xISHInstall -Repository $xISHInstallRepository
    }
    else
    {
        $path="$modulesPaths\xISHServer\$ishServerModuleName.psm1"
        Import-Module $path -Force
        Write-Warning "Not installed $ishServerModuleName. Instead loaded from $path"

        $path="$modulesPaths\xISHInstall\xISHInstall.psm1"
        Import-Module $path -Force        
        Write-Warning "Not installed xISHInstall. Instead loaded from $path"
    }
}
finally
{
}
