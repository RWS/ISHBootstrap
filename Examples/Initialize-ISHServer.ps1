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

$osUserCredential=Invoke-Expression (Get-ISHBootstrapperContextValue -ValuePath "OSUserCredentialExpression")
$prerequisitesSourcePath=Get-ISHBootstrapperContextValue -ValuePath "PrerequisitesSourcePath"
$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
$ishServerVersion=($ishVersion -split "\.")[0]
$installOracle=Get-ISHBootstrapperContextValue -ValuePath "InstallOracle" -DefaultValue $false

& $scriptsPaths\xISHServer\Upload-ISHServerPrerequisites.ps1 -Computer $computerName -PrerequisitesSourcePath $prerequisitesSourcePath -ISHServerVersion $ishServerVersion
& $scriptsPaths\xISHServer\Install-ISHServerPrerequisites.ps1 -Computer $computerName -ISHServerVersion $ishServerVersion -InstallOracle:$installOracle

if($computerName)
{
    $credentialForCredSSP=Invoke-Expression (Get-ISHBootstrapperContextValue -ValuePath "CredentialForCredSSPExpression")
    $useFQDNWithCredSSP=Get-ISHBootstrapperContextValue -ValuePath "UseFQDNWithCredSSP" -DefaultValue $true
    if($useFQDNWithCredSSP)
    {
        $fqdn=[System.Net.Dns]::GetHostByName($computerName)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
        & $scriptsPaths\xISHServer\Initialize-ISHServerOSUser.ps1 -Computer $fqdn -ISHServerVersion $ishServerVersion -CrentialForCredSSP $credentialForCredSSP -OSUser ($osUserCredential.UserName)
    }
    else
    {
        $sessionOptionsWithCredSSPExpression=Get-ISHBootstrapperContextValue -ValuePath "SessionOptionsWithCredSSPExpression" -DefaultValue $null
        if($sessionOptionsWithCredSSPExpression)
        {
            $sessionOptionsWithCredSSP=Invoke-Expression $sessionOptionsWithCredSSPExpression
        }
        & $scriptsPaths\xISHServer\Initialize-ISHServerOSUser.ps1 -Computer $computerName -ISHServerVersion $ishServerVersion -CrentialForCredSSP $credentialForCredSSP -SessionOptions $sessionOptionsWithCredSSP -OSUser ($osUserCredential.UserName)
    }
    & $scriptsPaths\xISHServer\Initialize-ISHServerOSUserRegion.ps1 -Computer $computerName -ISHServerVersion $ishServerVersion -OSUserCredential $osUserCredential
}
else
{
   & $scriptsPaths\xISHServer\Initialize-ISHServerOSUser.ps1 -ISHServerVersion $ishServerVersion -OSUser ($osUserCredential.UserName)
   Write-Warning "Cannot execute $scriptsPaths\xISHServer\Initialize-ISHServerOSUserRegion.ps1 locally."
}
& $scriptsPaths\IIS\New-IISSslBinding.ps1 -Computer $computerName

if($computerName)
{
    & $scriptsPaths\Helpers\Invoke-Restart.ps1 -Computer $computerName
}
else
{
    Write-Host "Please restart the computer before continuing ..."
}
