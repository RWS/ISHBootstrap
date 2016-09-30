if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
$credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke
if(-not $computerName)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

$isSupported=& $scriptsPaths\xISHServer\Test-SupportedServer.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion
if(-not $isSupported)
{
    return
}

$osUserCredential=Get-ISHBootstrapperContextValue -ValuePath "OSUserCredentialExpression" -Invoke
$prerequisitesSourcePath=Get-ISHBootstrapperContextValue -ValuePath "PrerequisitesSourcePath"
$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
$ishServerVersion=($ishVersion -split "\.")[0]
$installOracle=Get-ISHBootstrapperContextValue -ValuePath "InstallOracle" -DefaultValue $false

& $scriptsPaths\xISHServer\Upload-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -PrerequisitesSourcePath $prerequisitesSourcePath -ISHServerVersion $ishServerVersion
& $scriptsPaths\xISHServer\Install-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -InstallOracle:$installOracle

if($computerName)
{
    if(Get-ISHBootstrapperContextValue -ValuePath "Domain")
    {
        $useFQDNWithCredSSP=Get-ISHBootstrapperContextValue -ValuePath "UseFQDNWithCredSSP" -DefaultValue $true
        if($useFQDNWithCredSSP)
        {
            $fqdn=[System.Net.Dns]::GetHostByName($computerName)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
            & $scriptsPaths\xISHServer\Initialize-ISHServerOSUser.ps1 -Computer $fqdn -Credential $credential -ISHServerVersion $ishServerVersion -OSUser ($osUserCredential.UserName) -CredSSP
        }
        else
        {
            $sessionOptionsWithCredSSP=Get-ISHBootstrapperContextValue -ValuePath "SessionOptionsWithCredSSPExpression" -Invoke
            & $scriptsPaths\xISHServer\Initialize-ISHServerOSUser.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -SessionOptions $sessionOptionsWithCredSSP -OSUser ($osUserCredential.UserName) -CredSSP
        }
    }
    else
    {
        & $scriptsPaths\xISHServer\Initialize-ISHServerOSUser.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -OSUser ($osUserCredential.UserName)
    }
    & $scriptsPaths\xISHServer\Initialize-ISHServerOSUserRegion.ps1 -Computer $computerName -OSUserCredential $osUserCredential -ISHServerVersion $ishServerVersion
}
else
{
   & $scriptsPaths\xISHServer\Initialize-ISHServerOSUser.ps1 -ISHServerVersion $ishServerVersion -OSUser ($osUserCredential.UserName)
   Write-Warning "Cannot execute $scriptsPaths\xISHServer\Initialize-ISHServerOSUserRegion.ps1 locally."
}
& $scriptsPaths\IIS\New-IISSslBinding.ps1 -Computer $computerName -Credential $credential

if($computerName)
{
    & $scriptsPaths\Helpers\Invoke-Restart.ps1 -Computer $computerName -Credential $credential
}
else
{
    Write-Host "Please restart the computer before continuing ..."
}
