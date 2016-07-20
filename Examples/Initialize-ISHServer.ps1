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
else
{
    $fqdn=[System.Net.Dns]::GetHostByName($computerName)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
    $credentialForCredSSP=Invoke-Expression (Get-ISHBootstrapperContextValue -ValuePath "CredentialForCredSSPExpression")
    $osUserCredential=Invoke-Expression (Get-ISHBootstrapperContextValue -ValuePath "OSUserCredentialExpression")
}

$prerequisitesSourcePath=Get-ISHBootstrapperContextValue -ValuePath "PrerequisitesSourcePath"
$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
$ishServerVersion=($ishVersion -split "\.")[0]

& $scriptsPaths\ISHServer\Upload-ISHServerPrerequisites.ps1 -Computer $computerName -PrerequisitesSourcePath $prerequisitesSourcePath -ISHServerVersion $ishServerVersion
& $scriptsPaths\ISHServer\Install-ISHServerPrerequisites.ps1 -Computer $computerName -ISHServerVersion $ishServerVersion

& $scriptsPaths\ISHServer\Initialize-ISHServerOSUser.ps1 -Computer $fqdn -ISHServerVersion $ishServerVersion -CrentialForCredSSP $credentialForCredSSP -OSUser ($osUserCredential.UserName)
& $scriptsPaths\ISHServer\Initialize-ISHServerOSUserRegion.ps1 -Computer $computerName -ISHServerVersion $ishServerVersion -OSUserCredential $osUserCredential

& $scriptsPaths\IIS\New-IISSslBinding.ps1 -Computer $computerName
& $scriptsPaths\Helpers\Invoke-Restart.ps1 -Computer $computerName
