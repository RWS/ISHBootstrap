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

if(-not $computerName)
{
    Write-Warning "xISHServer will be imported from the repository"
    Remove-Module -Name xISHServer.12 -ErrorAction SilentlyContinue
    Remove-Module -Name xISHServer.13 -ErrorAction SilentlyContinue
    Import-Module "$sourcePath\Modules\xISHServer\xISHServer.$ishServerVersion.psm1"
}

$installOracle=Get-ISHBootstrapperContextValue -ValuePath "InstallOracle" -DefaultValue $false
$installMSXML=(($ishVersion -eq "12.0.0") -or ($ishVersion -eq "12.0.1"))
$isSupported=& $scriptsPaths\xISHServer\Test-SupportedServer.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion
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
    & $scriptsPaths\xISHServer\Upload-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -PrerequisitesSourcePath $prerequisitesSourcePath -ISHServerVersion $ishServerVersion
}
if($ftp)
{
    & $scriptsPaths\xISHServer\Get-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -FTPHost $ftpHost -FTPCredential $ftpCredential -FTPFolder $ftpISHServerFolder
}

& $scriptsPaths\xISHServer\Install-ISHServerPrerequisites.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -InstallOracle:$installOracle -InstallMSXML4:$installMSXML

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

if($unc)
{
    if($unc.AntennaHouseLicensePath)
    {
        & $scriptsPaths\xISHServer\Set-ISHAntennaHouseLicense.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -FilePath $unc.AntennaHouseLicensePath
    }
}
if($ftp)
{
    if($ftp.AntennaHouseLicensePath)
    {
        & $scriptsPaths\xISHServer\Set-ISHAntennaHouseLicense.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -FTPHost $ftpHost -FTPCredential $ftpCredential -FTPPath $ftp.AntennaHouseLicensePath
    }
}


if($computerName)
{
    & $scriptsPaths\Helpers\Invoke-Restart.ps1 -Computer $computerName -Credential $credential
}
else
{
    Write-Warning "Please restart the computer before continuing ..."
}
