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
$serverScriptsPaths="$sourcePath\Server"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextSource.ps1"
. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
$credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke
if(-not $computerName)
{
    & "$serverScriptsPaths\Helpers\Test-Administrator.ps1"
}

$osUserCredential=Get-ISHBootstrapperContextValue -ValuePath "OSUserCredentialExpression" -Invoke
$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
$ishServerVersion=($ishVersion -split "\.")[0]

$installOracle=Get-ISHBootstrapperContextValue -ValuePath "InstallOracle" -DefaultValue $false
$installMSXML=(($ishVersion -eq "12.0.0") -or ($ishVersion -eq "12.0.1"))
$isSupported=& $serverScriptsPaths\ISHServer\Test-SupportedServer.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion
if(-not $isSupported)
{
    return
}
$unc=Get-ISHBootstrapperContextSource -UNC
$ftp=Get-ISHBootstrapperContextSource -FTP
$awss3=Get-ISHBootstrapperContextSource -AWSS3
$azurefilestorage=Get-ISHBootstrapperContextSource -AzureFileStorage
$azureblobstorage=Get-ISHBootstrapperContextSource -AzureBlobStorage

if($unc)
{
    & $serverScriptsPaths\ISHServer\Upload-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -PrerequisitesSourcePath $unc.ISHServerFolder -ISHServerVersion $ishServerVersion
}
if($ftp)
{
    & $serverScriptsPaths\ISHServer\Get-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -FTPHost $ftp.Host -FTPCredential $ftp.Credential -FTPFolder $ftp.ISHServerFolder
}
if($awss3)
{
    & $serverScriptsPaths\ISHServer\Get-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -BucketName $awss3.BucketName -FolderKey $awss3.ISHServerFolderKey -AccessKey $awss3.AccessKey -SecretKey $awss3.SecretKey
}
if($azurefilestorage)
{
    & $serverScriptsPaths\ISHServer\Get-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -ShareName $azurefilestorage.ShareName -FolderPath $azurefilestorage.ISHServerFolderPath  -StorageAccountName $azurefilestorage.StorageAccountName -StorageAccountKey $azurefilestorage.StorageAccountKey
}
if($azureblobstorage)
{
    & $serverScriptsPaths\ISHServer\Get-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -ContainerName $azureblobstorage.ContainerName -FolderPath $azureblobstorage.ISHServerFolderPath  -StorageAccountName $azureblobstorage.StorageAccountName -StorageAccountKey $azureblobstorage.StorageAccountKey
}

& $serverScriptsPaths\ISHServer\Install-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -InstallOracle:$installOracle -InstallMSXML4:$installMSXML

if($computerName)
{
    if(Get-ISHBootstrapperContextValue -ValuePath "Domain")
    {
        $useFQDNWithCredSSP=Get-ISHBootstrapperContextValue -ValuePath "UseFQDNWithCredSSP" -DefaultValue $true
        if($useFQDNWithCredSSP)
        {
            $fqdn=[System.Net.Dns]::GetHostByName($computerName)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
             & $serverScriptsPaths\ISHServer\Initialize-ISHServerOSUser.ps1 -Computer $fqdn -Credential $credential -ISHServerVersion $ishServerVersion -OSUserCredential $osUserCredential -CredSSP
        }
        else
        {
            $sessionOptionsWithCredSSP=Get-ISHBootstrapperContextValue -ValuePath "SessionOptionsWithCredSSPExpression" -Invoke
             & $serverScriptsPaths\ISHServer\Initialize-ISHServerOSUser.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -SessionOptions $sessionOptionsWithCredSSP -OSUserCredential $osUserCredential -CredSSP
        }
    }
    else
    {
         & $serverScriptsPaths\ISHServer\Initialize-ISHServerOSUser.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -OSUserCredential $osUserCredential
    }
     & $serverScriptsPaths\ISHServer\Initialize-ISHServerOSUserRegion.ps1 -Computer $computerName -OSUserCredential $osUserCredential -ISHServerVersion $ishServerVersion
}
else
{
   & $serverScriptsPaths\ISHServer\Initialize-ISHServerOSUser.ps1 -ISHServerVersion $ishServerVersion -OSUserCredential $osUserCredential
   & $serverScriptsPaths\ISHServer\Initialize-ISHServerOSUserRegion.ps1 -OSUserCredential $osUserCredential -ISHServerVersion $ishServerVersion
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
            $certificate=& $serverScriptsPaths\Certificates\Install-Certificate.ps1 -Computer $fqdn -Credential $credential -CredSSP @hash
        }
        else
        {
             $certificate=& $serverScriptsPaths\Certificates\Install-Certificate.ps1 @hash
        }
    }

    & $serverScriptsPaths\IIS\Set-IISSslBinding.ps1 -Computer $computerName -Credential $credential -Thumbprint $certificate.Thumbprint
}
else
{
    & $serverScriptsPaths\IIS\Set-IISSslBinding.ps1 -Computer $computerName -Credential $credential
}

if($unc)
{
    if($unc.AntennaHouseLicensePath)
    {
        & $serverScriptsPaths\ISHServer\Set-ISHAntennaHouseLicense.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -FilePath $unc.AntennaHouseLicensePath
    }
}
if($ftp)
{
    if($ftp.AntennaHouseLicensePath)
    {
        & $serverScriptsPaths\ISHServer\Set-ISHAntennaHouseLicense.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -FTPHost $ftp.Host -FTPCredential $ftp.Credential -FTPPath $ftp.AntennaHouseLicensePath
    }
}

if($awss3)
{
    if($awss3.AntennaHouseLicenseKey)
    {
        & $serverScriptsPaths\ISHServer\Set-ISHAntennaHouseLicense.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion  -BucketName $awss3.BucketName -Key $awss3.AntennaHouseLicenseKey -AccessKey $awss3.AccessKey -SecretKey $awss3.SecretKey
    }
}

if($azurefilestorage)
{
    if($azurefilestorage.AntennaHouseLicenseKey)
    {
        & $serverScriptsPaths\ISHServer\Set-ISHAntennaHouseLicense.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -ShareName $azurefilestorage.ShareName -Path $azureblobstorage.AntennaHouseLicenseKey -StorageAccountName $azurefilestorage.StorageAccountName -StorageAccountKey $azurefilestorage.StorageAccountKey
    }
}

if($azureblobstorage)
{
    if($azureblobstorage.AntennaHouseLicenseKey)
    {
        & $serverScriptsPaths\ISHServer\Set-ISHAntennaHouseLicense.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -ContainerName $azureblobstorage.ContainerName -BlobName $azureblobstorage.AntennaHouseLicenseKey -StorageAccountName $azureblobstorage.StorageAccountName -StorageAccountKey $azureblobstorage.StorageAccountKey
    }
}


if($computerName)
{
    & $serverScriptsPaths\Helpers\Restart-Server.ps1 -Computer $computerName -Credential $credential
}
else
{
    Write-Warning "Please restart the computer before continuing ..."
}