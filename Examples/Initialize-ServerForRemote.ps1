if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null

if(-not $computerName)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

if($computerName)
{
    $enableSecureWinRM=Get-ISHBootstrapperContextValue -ValuePath "EnableSecureWinRM"
    $certificateAuthority=Get-ISHBootstrapperContextValue -ValuePath "CertificateAuthority"
    $targetPath="\\$computerName\C$\Users\$env:USERNAME\Documents\WindowsPowerShell\"
    if(-not (Test-Path $targetPath))
    {
        New-Item $targetPath -ItemType Directory | Out-Null
    }
    Copy-Item -Path "$scriptsPaths\Remote\Initialize-Remote.ps1" -Destination $targetPath -Force
    Write-Host "Login to $Computer and execute locally C:\Users\$env:USERNAME\Documents\WindowsPowerShell\Initialize-Remote.ps1 -CertificateAuthority `"$certificateAuthority`""
}
else
{
    & "$scriptsPaths\Remote\Initialize-Remote.ps1"
}