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

$webCertificate=Get-ISHBootstrapperContextValue -ValuePath "WebCertificate"
$parameters=@(
    "-CertificateAuthority `"$($webCertificate.Authority)`""
)
if($webCertificate.OrganizationalUnit)
{
    $parameters+="-OrganizationalUnit `"$($webCertificate.OrganizationalUnit)`""
}
if($webCertificate.Organization)
{
    $parameters+="-Organization `"$($webCertificate.Organization)`""
}
if($webCertificate.Locality)
{
    $parameters+="-Locality `"$($webCertificate.Locality)`""
}
if($webCertificate.State)
{
    $parameters+="-State `"$($webCertificate.State)`""
}
if($webCertificate.Country)
{
    $parameters+="-Country `"$($webCertificate.Country)`""
}
$scriptLine="Initialize-Remote.ps1 "+ ($parameters -join ' ')



if($computerName)
{
    $targetPath="\\$computerName\C$\Users\$env:USERNAME\Documents\WindowsPowerShell\"
    if(-not (Test-Path $targetPath))
    {
        New-Item $targetPath -ItemType Directory | Out-Null
    }
    Copy-Item -Path "$scriptsPaths\Remote\Initialize-Remote.ps1" -Destination $targetPath -Force
    
    Write-Host "Login to $Computer and execute locally C:\Users\$env:USERNAME\Documents\WindowsPowerShell\$scriptLine"
}
else
{
    Write-Host "Executing $scriptsPaths\Remote\$scriptLine"
    & "$scriptsPaths\Remote\$scriptLine"
}