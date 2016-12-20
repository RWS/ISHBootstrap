<#
# Copyright (c) 2014 All Rights Reserved by the SDL Group.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#>

if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
$credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke
if(-not $computerName)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

$osUserCredential=Get-ISHBootstrapperContextValue -ValuePath "OSUserCredentialExpression" -Invoke
$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
$ishServerVersion=($ishVersion -split "\.")[0]

$installOracle=Get-ISHBootstrapperContextValue -ValuePath "InstallOracle" -DefaultValue $false
$installMSXML=(($ishVersion -eq "12.0.0") -or ($ishVersion -eq "12.0.1"))
$isSupported=& $scriptsPaths\ISHServer\Test-SupportedServer.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion
if(-not $isSupported)
{
    return
}
$unc=Get-ISHBootstrapperContextValue -ValuePath "UNC" -DefaultValue $null
$ftp=Get-ISHBootstrapperContextValue -ValuePath "FTP" -DefaultValue $null
if($ftp)
{
    $ftpHost=$ftp.Host
    $ftpCredential=Get-ISHBootstrapperContextValue -ValuePath "FTP.CredentialExpression" -Invoke
    $ftpISHServerFolder=$ftp.ISHServerFolder
    $testHostBlock={
        Test-Connection $ftpHost -Quiet
    }
    $testHost=Invoke-CommandWrap -ComputerName $computerName -Credential $credential -ScriptBlock $testHostBlock -BlockName "Test $ftpHost" -UseParameters @("ftpHost")
    if(-not $testHost)
    {
        $ftpAlternateHost=$ftp.AlternativeHost
        Write-Warning "Using alternate host $ftpAlternateHost instead of $ftpHost"
        $ftpHost=$ftpAlternateHost
    }
}

if($unc)
{
    $prerequisitesSourcePath=$unc.ISHServerFolder
    & $scriptsPaths\ISHServer\Upload-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -PrerequisitesSourcePath $prerequisitesSourcePath -ISHServerVersion $ishServerVersion
}
if($ftp)
{
    & $scriptsPaths\ISHServer\Get-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -FTPHost $ftpHost -FTPCredential $ftpCredential -FTPFolder $ftpISHServerFolder
}

& $scriptsPaths\ISHServer\Install-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -InstallOracle:$installOracle -InstallMSXML4:$installMSXML

if($computerName)
{
    if(Get-ISHBootstrapperContextValue -ValuePath "Domain")
    {
        $useFQDNWithCredSSP=Get-ISHBootstrapperContextValue -ValuePath "UseFQDNWithCredSSP" -DefaultValue $true
        if($useFQDNWithCredSSP)
        {
            $fqdn=[System.Net.Dns]::GetHostByName($computerName)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
             & $scriptsPaths\ISHServer\Initialize-ISHServerOSUser.ps1 -Computer $fqdn -Credential $credential -ISHServerVersion $ishServerVersion -OSUser ($osUserCredential.UserName) -CredSSP
        }
        else
        {
            $sessionOptionsWithCredSSP=Get-ISHBootstrapperContextValue -ValuePath "SessionOptionsWithCredSSPExpression" -Invoke
             & $scriptsPaths\ISHServer\Initialize-ISHServerOSUser.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -SessionOptions $sessionOptionsWithCredSSP -OSUser ($osUserCredential.UserName) -CredSSP
        }
    }
    else
    {
         & $scriptsPaths\ISHServer\Initialize-ISHServerOSUser.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -OSUser ($osUserCredential.UserName)
    }
     & $scriptsPaths\ISHServer\Initialize-ISHServerOSUserRegion.ps1 -Computer $computerName -OSUserCredential $osUserCredential -ISHServerVersion $ishServerVersion
}
else
{
   & $scriptsPaths\ISHServer\Initialize-ISHServerOSUser.ps1 -ISHServerVersion $ishServerVersion -OSUser ($osUserCredential.UserName)
   Write-Warning "Cannot execute $scriptsPaths\ISHServer\Initialize-ISHServerOSUserRegion.ps1 locally."
}

$webCertificate=Get-ISHBootstrapperContextValue -ValuePath "WebCertificate"
if($webCertificate)
{
    $hash=@{
        CertificateAuthority=$webCertificate.Authority
    }
    #TODO: Add logic for load ballanced environments
    if($computerName)
    {
        $hash.Hostname=[System.Net.Dns]::GetHostByName($computerName)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() }
    }
    else
    {
        $hash.Hostname=[System.Net.Dns]::GetHostByName($env:COMPUTERNAME)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() }
    }
    if($webCertificate.OrganizationalUnit)
    {
        $hash.OrganizationalUnit=$webCertificate.OrganizationalUnit
    }
    if($webCertificate.Organization)
    {
        $hash.Organization=$webCertificate.Organization
    }
    if($webCertificate.Locality)
    {
        $hash.Locality=$webCertificate.Locality
    }
    if($webCertificate.State)
    {
        $hash.State=$webCertificate.State
    }
    if($webCertificate.Country)
    {
        $hash.Country=$webCertificate.Country
    }

    if($computerName)
    {
        if(Get-ISHBootstrapperContextValue -ValuePath "Domain")
        {
            $fqdn=[System.Net.Dns]::GetHostByName($computerName)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
            $certificate=& $scriptsPaths\Certificates\Install-Certificate.ps1 -Computer $fqdn -Credential $credential -CredSSP @hash
        }
        else
        {
             $certificate=& $scriptsPaths\Certificates\Install-Certificate.ps1 @hash
        }
    }

    & $scriptsPaths\IIS\Set-IISSslBinding.ps1 -Computer $computerName -Credential $credential -Thumbprint $certificate.Thumbprint
}
else
{
    & $scriptsPaths\IIS\Set-IISSslBinding.ps1 -Computer $computerName -Credential $credential
}

if($unc)
{
    if($unc.AntennaHouseLicensePath)
    {
        & $scriptsPaths\ISHServer\Set-ISHAntennaHouseLicense.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -FilePath $unc.AntennaHouseLicensePath
    }
}
if($ftp)
{
    if($ftp.AntennaHouseLicensePath)
    {
        & $scriptsPaths\ISHServer\Set-ISHAntennaHouseLicense.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -FTPHost $ftpHost -FTPCredential $ftpCredential -FTPPath $ftp.AntennaHouseLicensePath
    }
}


if($computerName)
{
    & $scriptsPaths\Helpers\Restart-Server.ps1 -Computer $computerName -Credential $credential
}
else
{
    Write-Warning "Please restart the computer before continuing ..."
}