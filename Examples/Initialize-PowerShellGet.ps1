if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName"

if(-not $computerName)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

& $scriptsPaths\PackageManagement\Install-PackageManagement.ps1 -Computer $computerName
& $scriptsPaths\PackageManagement\Install-NugetPackageProvider.ps1 -Computer $computerName

$psRepository=Get-ISHBootstrapperContextValue -ValuePath "PSRepository"
$psRepository |ForEach-Object {
    & $scriptsPaths\PowerShellGet\Register-Repository.ps1 -Computer $computerName -Name $_.Name -SourceLocation $_.SourceLocation -PublishLocation $_.PublishLocation -InstallationPolicy $_.InstallationPolicy
}

$installProcessExplorer=Get-ISHBootstrapperContextValue -ValuePath "InstallProcessExplorer"
if($installProcessExplorer)
{
    & $scriptsPaths\Helpers\Install-ProcessExplorer.ps1 -Computer $computerName
}
