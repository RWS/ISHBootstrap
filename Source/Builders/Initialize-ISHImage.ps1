#reguires -runasadministrator

<#
# Script developed for Windows Server 2016 
# Windows PowerShell 5.1 is already installed
# PowerShellGet is also available
#>

param(
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [Parameter(Mandatory=$true,ParameterSetName="From AWS S3")]
    [ValidateSet("12.0.3","12.0.4","13.0.0","13.0.1","13.0.2","14.0.0")]
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
    [string]$SecretKey,
    [Parameter(Mandatory=$false,ParameterSetName="From FTP")]
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [bool]$InstallISHPrerequisites=$true,
    [Parameter(Mandatory=$false,ParameterSetName="From FTP")]
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [bool]$InstallISHApplicationServer=$true
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

$mockOSUserName="MockOSUser"
$mockOSUserPassword="Password123"
$mockOSUserCredential=New-Object System.Management.Automation.PSCredential($mockOSUserName,(ConvertTo-SecureString $mockOSUserPassword -AsPlainText -Force))
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

if ($InstallISHPrerequisites)
{
    #region 1. Download and install pre-requisites
    $blockName="Installing ISH prerequisities"
    Write-Progress @scriptProgress -Status $blockName
    Write-Host $blockName

    & $serverScriptsPath\ISHServer\Get-ISHServerPrerequisites.ps1 -ISHServerVersion $ishServerVersion @ishServerPrerequisitesHash
    & $serverScriptsPath\ISHServer\Install-ISHServerPrerequisites.ps1 -ISHServerVersion $ishServerVersion #-InstallMSXML4:$installMSXML
    #endregion
}

if ($InstallISHApplicationServer)
{
    #region 2. Copy and Expand CD
    $blockName="Copying ISHCD"
    Write-Progress @scriptProgress -Status $blockName
    Write-Host $blockName

    & $serverScriptsPath\ISHServer\Copy-ISHCD.ps1 -ISHServerVersion $ishServerVersion @ishCDHash
    #endregion
    
    #region 3. Initial os user
    $blockName="Initializing mock user"
    Write-Progress @scriptProgress -Status $blockName
    Write-Host $blockName

    if(Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable)
    {
        if(-not (Get-LocalUser -Name $mockOSUserCredential.UserName -ErrorAction SilentlyContinue))
        {
            Write-Host "Adding mock user"
            New-LocalUser -Name $mockOSUserCredential.UserName -Password $mockOSUserCredential.Password -AccountNeverExpires -PasswordNeverExpires
        }
    }
    else
    {
        NET USER $mockOSUserName $mockOSUserPassword /ADD
        # Uncheck 'User must change password'
        $user = [adsi]"WinNT://$env:computername/$mockOSUserName"
        $user.UserFlags.value = $user.UserFlags.value -bor 0x10000
        $user.CommitChanges()    
    }
    & $serverScriptsPath\ISHServer\Initialize-ISHServerOSUser.ps1 -ISHServerVersion $ishServerVersion -OSUserCredential $mockOSUserCredential

    #endregion

    #region 4. Create Self Signed Certificate and Assign to IIS HTTPS Binding
    $blockName="Creating mock certificate"
    Write-Progress @scriptProgress -Status $blockName
    Write-Host $blockName

    # Using this provider with the self-signed certificate is very important because otherwise the .net code in ishsts cannot use to encrypt.
    # INFO http://stackoverflow.com/questions/36295461/why-does-my-private-key-not-work-to-decrypt-a-key-encrypted-by-the-public-key
    $providerName="Microsoft Strong Cryptographic Provider"
    if($PSVersionTable.PSVersion.Major -ge 5)
    {
        $certificate=New-SelfSignedCertificate -DnsName "mock-$($env:COMPUTERNAME)" -CertStoreLocation "cert:\LocalMachine\My" -Provider $providerName
    }
    else
    {
        # -Parameter not supported on PowerShell v4 New-SelfSignedCertificate
        $certificate=New-SelfSignedCertificate -DnsName "mock-$($env:COMPUTERNAME)" -CertStoreLocation "cert:\LocalMachine\My"
    }
    $rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList Root, LocalMachine
    $rootStore.Open("MaxAllowed")
    $rootStore.Add($certificate)
    $rootStore.Close()
    & $serverScriptsPath\IIS\Set-IISSslBinding.ps1 -Thumbprint $certificate.Thumbprint

    #endregion

    #region 5. [DEVELOPFRIENDLY] Install IIS Management Console

    if($DevelopFriendly)
    {
        & ..\DevelopFriendly\Install-IISManagement.ps1
    }

    #endregion

    #region 6. Mock database
    if($mockDatabase)
    {
        & $dbScriptsPath\Restore-MockDatabase.ps1 -ISHVersion $ishVersion
    }
    #endregion
    
    #region 7. Install ISH
    $blockName="Installing ISH"
    Write-Progress @scriptProgress -Status $blockName
    Write-Host $blockName

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

    #region 8. Stopping all
    $blockName="Stopping processes"
    Write-Progress @scriptProgress -Status $blockName
    Write-Host $blockName

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

    #endregion

    #region 9. Clean up 
    $blockName="Cleaning up"
    Write-Progress @scriptProgress -Status $blockName

    Write-Host "Removing mock user"
    if(Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable)
    {
        $null=Remove-LocalUser -Name $mockOSUserCredential.UserName
    }
    else
    {
        NET USER $mockOSUserName /DELETE
    }
    Write-Host "Removing mock certificate"
    $null=Get-Item -Path Cert:\LocalMachine\My\$($certificate.Thumbprint)|Remove-Item -Force
    #endregion
}

#region Clean up temp files 
$blockName="Cleaning up temp files"
Write-Progress @scriptProgress -Status $blockName

Write-Host "Removing temp files"
$null=Get-ChildItem -Path $env:Temp |Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
#endregion

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
