#reguires -runasadministrator

<#
# Script developed for Windows Server 2016 
# Windows PowerShell 5.1 is already installed
# PowerShellGet is also available
#>

param(
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [Parameter(Mandatory=$true,ParameterSetName="From AWS S3")]
    [ValidateSet("12.0.3","12.0.4","13.0.0")]
    [string]$ISHVersion,
    [Parameter(Mandatory=$false,ParameterSetName="From FTP")]
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [string]$ConnectionString=$null,
    [Parameter(Mandatory=$false,ParameterSetName="From FTP")]
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [switch]$DevelopFriendly=$false,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [string]$FTPHost,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [string]$FTPCredential,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [string]$ISHServerFolder,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [string]$ISHCDFolder,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [string]$ISHCDFileName,
    [Parameter(Mandatory=$true,ParameterSetName="From AWS S3")]
    [string]$BucketName,
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [string]$AccessKey,
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [string]$SecretKey
)

$cmdletsPaths="$PSScriptRoot\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

$dbScriptsPath=Join-Path $PSScriptRoot Database
$mockDatabase=-not $ConnectionString

$ishServerVersion=($ISHVersion -split "\.")[0]
$ishRevision=($ISHVersion -split "\.")[2]

#region Initialize Values after install

$serverScriptsPath=Join-Path "$PSScriptRoot\.." "Server"

$mockOSUserCredential=New-Object System.Management.Automation.PSCredential("MockOSUser",(ConvertTo-SecureString "Password123" -AsPlainText -Force))
if($mockDatabase)
{
    $ConnectionString=& $dbScriptsPath\Get-MockConnectionString.ps1
}
#endregion


#region Install ISH Prerequisites

# Code is inspired by ISHBootstrap

if($ISHCDFolder.EndsWith("/"))
{
    $ISHCDFolder=$ISHCDFolder.TrimEnd("/")
}
switch($PSCmdlet.ParameterSetName) {
    'From AWS S3' {
        $ishCDHash=@{
            BucketName=$BucketName
            Key="$ISHCDFolder/$ISHCDFileName"
            AccessKey=$AccessKey
            SecretKey=$SecretKey
        }
        $ishServerPrerequisitesHash=@{
            BucketName=$BucketName
            FolderKey=$ISHServerFolder
            AccessKey=$AccessKey
            SecretKey=$SecretKey
        }
        break
    }
    'From FTP' {
        $ishCDHash=@{
            FTPHost=$FTPHost
            FTPCredential=$FTPCredential
            FTPPath="$ISHCDFolder/$ISHCDFileName"
        }
        $ishServerPrerequisitesHash=@{
            FTPHost=$FTPHost
            FTPCredential=$FTPCredential
            FTPFolder=$ISHServerFolder
        }
        break
    }
}

#region 1. Copy and Expand CD
$blockName="Copying ISHCD"
Write-Progress @scriptProgress -Status $blockName
Write-Information $blockName

& $serverScriptsPath\ISHServer\Copy-ISHCD.ps1 -ISHServerVersion $ishServerVersion @ishCDHash
#endregion

#region 2. Download and install pre-requisites
$blockName="Installing ISH prerequisities"
Write-Progress @scriptProgress -Status $blockName
Write-Information $blockName

& $serverScriptsPath\ISHServer\Get-ISHServerPrerequisites.ps1 -ISHServerVersion $ishServerVersion @ishServerPrerequisitesHash
& $serverScriptsPath\ISHServer\Install-ISHServerPrerequisites.ps1 -ISHServerVersion $ishServerVersion #-InstallMSXML4:$installMSXML
#endregion

#region 3. Initial os user
$blockName="Initializing mock user"
Write-Progress @scriptProgress -Status $blockName
Write-Information $blockName

if(-not (Get-LocalUser -Name $mockOSUserCredential.UserName -ErrorAction SilentlyContinue))
{
    Write-Information "Adding mock user"
    New-LocalUser -Name $mockOSUserCredential.UserName -Password $mockOSUserCredential.Password -AccountNeverExpires -PasswordNeverExpires
}
& $serverScriptsPath\ISHServer\Initialize-ISHServerOSUser.ps1 -ISHServerVersion $ishServerVersion -OSUser ($mockOSUserCredential.UserName)

#endregion

#region 4. Create Self Signed Certificate and Assign to IIS HTTPS Binding
$blockName="Creating mock certificate"
Write-Progress @scriptProgress -Status $blockName
Write-Information $blockName

# Using this provider with the self-signed certificate is very important because otherwise the .net code in ishsts cannot use to encrypt.
# INFO http://stackoverflow.com/questions/36295461/why-does-my-private-key-not-work-to-decrypt-a-key-encrypted-by-the-public-key
$providerName="Microsoft Strong Cryptographic Provider"
$certificate=New-SelfSignedCertificate -DnsName "mock-$($env:COMPUTERNAME)" -CertStoreLocation "cert:\LocalMachine\My" -Provider $providerName
$rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList Root, LocalMachine
$rootStore.Open("MaxAllowed")
$rootStore.Add($certificate)
$rootStore.Close()
& $serverScriptsPath\IIS\Set-IISSslBinding.ps1 -Thumbprint $certificate.Thumbprint

#endregion

#endregion

#region [DEVELOPFRIENDLY] Install IIS Management Console

if($DevelopFriendly)
{
    & ..\DevelopFriendly\Install-IISManagement.ps1
}

#endregion

#region Mock database
if($mockDatabase)
{
    & $dbScriptsPath\Install-MockDatabase.ps1 -ISHVersion $ishVersion
    & $dbScriptsPath\Initialize-MockDatabase.ps1 -ISHVersion $ishVersion -DevelopFriendly:$developFriendly
}
#endregion

#region Install ISH
$blockName="Installing ISH"
Write-Progress @scriptProgress -Status $blockName
Write-Information $blockName

$installHash=@{
    ISHVersion=$ISHVersion
    OSUserCredential=$mockOSUserCredential
    HostName="MockHostName"
    LocalServiceHostName="MockLocalServiceHostName"
    MachineName="MockMachineName"
    ConnectionString=$ConnectionString
}

& $serverScriptsPath\Install\Install-ISHDeployment.ps1 @installHash
#endregion

#region Stopping all
$blockName="Stopping processes"
Write-Progress @scriptProgress -Status $blockName
Write-Information $blockName

# Web Application pools
Import-Module WebAdministration
Get-ISHDeploymentParameters| Where-Object -Property Name -Like "infoshare*webappname"| ForEach-Object {
    Stop-WebAppPool -Name "TrisoftAppPool$($_.Value)" -ErrorAction SilentlyContinue
}

# Windows services
Get-Service -Name "Trisoft InfoShare*"|Stop-Service -Force

# COMPlus
$comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
$catalog = New-Object -com COMAdmin.COMAdminCatalog 
$applications = $catalog.getcollection("Applications") 
$applications.populate()

$comAdmin.ShutdownApplication("Trisoft-InfoShare-Author")

# MockDatabase
if($mockDatabase)
{
    & $dbScriptsPath\Stop-MockDatabase.ps1
}

#endregion

#region Clean up 
$blockName="Cleaning up"
Write-Progress @scriptProgress -Status $blockName

Write-Information "Removing mock user"
$null=Remove-LocalUser -Name $mockOSUserCredential.UserName
Write-Information "Removing mock certificate"
$null=Get-Item -Path Cert:\LocalMachine\My\$($certificate.Thumbprint)|Remove-Item -Force

Write-Information "Removing temp files"
$null=Get-ChildItem -Path $env:Temp |Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
#endregion

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer