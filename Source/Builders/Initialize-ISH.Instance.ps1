#requires -runasadministrator

param(
    [Parameter(Mandatory=$true,ParameterSetName="External Database")]
    [string]$ConnectionString,
    [ValidateSet("sqlserver2014")]
    [Parameter(Mandatory=$false,ParameterSetName="External Database")]
    [string]$DbType="sqlserver2014",
    [Parameter(Mandatory=$true,ParameterSetName="External Database")]
    [Parameter(Mandatory=$true,ParameterSetName="Demo Database")]
    [pscredential]$OsUserCredentials,
    [Parameter(Mandatory=$true,ParameterSetName="External Database")]
    [Parameter(Mandatory=$true,ParameterSetName="Demo Database")]
    [string]$PFXCertificatePath,
    [Parameter(Mandatory=$true,ParameterSetName="External Database")]
    [Parameter(Mandatory=$true,ParameterSetName="Demo Database")]
    [securestring]$PFXCertificatePassword,
    [Parameter(Mandatory=$false,ParameterSetName="External Database")]
    [Parameter(Mandatory=$false,ParameterSetName="Demo Database")]
    [string]$HostName=$null
)

$cmdletsPaths="$PSScriptRoot\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

$dbScriptsPath=Join-Path $PSScriptRoot Database
$useMockedDatabaseAsDemo=$PSCmdlet.ParameterSetName -eq "Demo Database"

#region 1. Import Certificate

$blockName="Importing certificate"
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

$certificate=Import-PfxCertificate -Password $PFXCertificatePassword -FilePath $PFXCertificatePath -Exportable -CertStoreLocation "Cert:\LocalMachine\My"
Import-Module WebAdministration
Push-Location "IIS:\SslBindings" -StackName "IIS"
$certificate|Set-Item 0.0.0.0!443 |Out-Null
Pop-Location -StackName "IIS"

#endregion

#region 2. Initialize Values

$blockName="Getting deployment information"
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

$softwareVersion=Get-ISHDeployment |Select-Object -First 1 -ExpandProperty SoftwareVersion
$ishVersion="$($softwareVersion.Major).0.$($softwareVersion.Revision)"
$ishServerVersion=($ishVersion -split "\.")[0]

if($OsUserCredentials.UserName.StartsWith("$($env:computername)\"))
{
    $createLocalUser=$true
}
elseif($OsUserCredentials.UserName.StartsWith(".\"))
{
    Write-Host "Credentials normalization.Replaced .\ with $env:COMPUTERNAME"
    $OsUserCredentials=New-Object System.Management.Automation.PSCredential($OsUserCredentials.UserName.Replace(".",$env:COMPUTERNAME),$OsUserCredentials.Password)
    $createLocalUser=$true
}
elseif($OsUserCredentials.UserName.indexOf("\") -lt 0)
{
    Write-Host "Credentials normalization.Prefixed with $env:COMPUTERNAME"
    $OsUserCredentials=New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$($OsUserCredentials.UserName)",$OsUserCredentials.Password)
    $createLocalUser=$true
}
else
{
    $createLocalUser=$false
}


$osUserName=$OsUserCredentials.UserName
Write-Host "osUserName=$osUserName"
Write-Host "createLocalUser=$createLocalUser"
if($createLocalUser)
{
    $localUserNameToAdd=$osUserName.Substring($osUserName.IndexOf('\')+1)
    Write-Host "localUserNameToAdd=$localUserNameToAdd"
}
$osUserPassword=$OsUserCredentials.GetNetworkCredential().Password

#endregion

#region 3. Get all processes

$blockName="Getting all processes"
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

# Web Application pools
$ishAppPools=Get-ISHDeploymentParameters| Where-Object -Property Name -Like "infoshare*webappname"|ForEach-Object {
    Get-Item "IIS:\AppPools\TrisoftAppPool$($_.Value)"

    # There is something wrong with Get-IISAppPool|Set-Item
    # Import-Module IISAdministration
    #Get-IISAppPool -Name "TrisoftAppPool$($_.Value)"
}

# Web Sites
$ishWebSites=Get-ISHDeploymentParameters| Where-Object -Property Name -Like "infoshare*webappname"|ForEach-Object {
    Get-Item "IIS:\Sites\Default Web Site\$($_.Value)"
}

# Windows services
$ishServices=Get-Service -Name "Trisoft InfoShare*"


# COMPlus
$comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
$catalog = New-Object -com COMAdmin.COMAdminCatalog 
$applications = $catalog.getcollection("Applications") 
$applications.populate()
$trisoftInfoShareAuthorApplication=$applications|Where-Object -Property Name -EQ "Trisoft-InfoShare-Author"

#endregion

#region 4. Initialize OSUser
$blockName="Initializing osuser"    
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

if($createLocalUser)
{
    Write-Debug "Adding $localUserNameToAdd local user"
    if(Get-Module Microsoft.PowerShell.LocalAccounts -ListAvailable)
    {
        if(-not (Get-LocalUser -Name $localUserNameToAdd -ErrorAction SilentlyContinue))
        {
            New-LocalUser -Name $localUserNameToAdd -Password $OsUserCredentials.Password -AccountNeverExpires -PasswordNeverExpires
        }
    }
    else
    {
        NET USER $localUserNameToAdd $osUserPassword /ADD
        $user = [adsi]"WinNT://$env:computername/$localUserNameToAdd"
        $user.UserFlags.value = $user.UserFlags.value -bor 0x10000
        $user.CommitChanges()    
    }
    Write-Verbose "Added $localUserNameToAdd local user"
}

$arguments=@(
    "-Command"
    "' { Initialize-ISHRegional } '"
)
Initialize-ISHUser -OSUser $osUserName
$powerShellPath=& C:\Windows\System32\where.exe powershell

if(Test-Path -Path Variable:\PSSenderInfo)
{
    $useScheduledTask=$true
}
elseif($env:USERNAME -eq "NT AUTHORITY\SYSTEM")
{
    $useScheduledTask=$true
}
elseif($env:USERNAME -eq "$($env:computername)`$")
{
    $useScheduledTask=$true
}
else
{
    $useScheduledTask=$false
}

if($useScheduledTask)
{
    Write-Warning "Using a scheduled task to initialize $osUserName"
    Add-Privilege -AccountName $osUserName -Privilege SeBatchLogonRight
    $argumentList=$arguments -join ' '
    $command="Start-Process -FilePath powershell -LoadUserProfile -Wait -ArgumentList ""$argumentList"""
    $action = New-ScheduledTaskAction -Execute $powerShellPath -Argument "-Command '& { $command }'"
    $task = Register-ScheduledTask "Install Alex" -Action $action -User $osUserName -Password $osUserPassword
    Start-ScheduledTask -InputObject $task

    $state=($task|Get-ScheduledTask).State
    while($state -eq "Ready")
    {
        Start-Sleep -Milliseconds 500
        $state=($task|Get-ScheduledTask).State
    }
    $task|Unregister-ScheduledTask -Confirm:$false
    Remove-Privilege -AccountName $osUserName -Privilege SeBatchLogonRight
}
else
{
    Start-Process -FilePath $powerShellPath -ArgumentList $arguments -Credential $OsUserCredentials -LoadUserProfile -NoNewWindow  -Wait
}

#endregion

#region 5. Initialize Demo database

if($useMockedDatabaseAsDemo)
{
    $blockName="Initializing Demo database"
    Write-Progress @scriptProgress -Status $blockName
    Write-Host $blockName

    & $dbScriptsPath\Initialize-MockDatabase.ps1 -OSUserSqlUser $osUserName
    $ConnectionString=& $dbScriptsPath\Get-MockConnectionString.ps1
}

#endregion

#region 5. Setting process identities

$blockName="Setting process identities"    
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

$ishAppPools|ForEach-Object {
    $_.ProcessModel.UserName = $osUserName
    $_.ProcessModel.Password = $osUserPassword
    $_.processModel.identityType = 3
    $_.ProcessModel.LoadUserProfile=$true
    $_|Set-Item
}
$ishWebSites|ForEach-Object {
    Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name Username -Value $osUserName -PSPath IIS:\ -Location "Default Web Site/$($_.Name)"
    Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name Password -Value $osUserPassword -PSPath IIS:\ -Location "Default Web Site/$($_.Name)"
}

$ishServices|ForEach-Object {
    # https://gallery.technet.microsoft.com/Powershell-How-to-change-be88ce7e
    $svcD=gwmi win32_service -filter "name like '%$($_.Name)%'" 
    $svcD.change($null,$null,$null,$null,$null,$null,$osUserName,$osUserPassword,$null,$null,$null) 
}
$trisoftInfoShareAuthorApplication.Value("Identity") = $osUserName
$trisoftInfoShareAuthorApplication.Value("Password") = $osUserPassword
$applications.SaveChanges();
#endregion

#region 6. Change the database connection
$blockName="Setting database connection"  
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

if(-not $useMockedDatabaseAsDemo)
{

    Set-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Trisoft\Tridk\TridkApp\InfoShareAuthor'-Name "Connect" -Value $ConnectionString
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Trisoft\Tridk\TridkApp\InfoShareAuthor'-Name "ComponentName" -Value $DbType
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Trisoft\Tridk\TridkApp\InfoShareBuilders'-Name "Connect" -Value $ConnectionString
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Trisoft\Tridk\TridkApp\InfoShareBuilders'-Name "ComponentName" -Value $DbType
}
else
{
    # This is because the computer name can change
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Trisoft\Tridk\TridkApp\InfoShareAuthor'-Name "Connect" -Value $ConnectionString
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Trisoft\Tridk\TridkApp\InfoShareBuilders'-Name "Connect" -Value $ConnectionString
}
#endregion

#region 7. Hard replace files
$blockName="Replacing mock input parameters"
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

if($HostName)
{
    $baseHostName=$HostName
}
else
{
    $baseHostName=(($certificate.Subject -split ', ')[0] -split '=')[1].ToLower()
}

$deployment=Get-ISHDeployment
$deploymentParameters=Get-ISHDeploymentParameters
$projectSuffix=$deploymentParameters |Where-Object -Property Name -EQ projectSuffix|Select-Object -ExpandProperty Value

$webPath=$deployment.WebPath
$dataPath=$deployment.DataPath
$appPath=$deployment.AppPath
$ishDeployModuleVersion=(Get-Command Get-ISHDeployment).Module.Version
if($ishDeployModuleVersion -le [version]"1.2")
{
    $webPath=Join-Path $webPath "Web$projectSuffix"
    $dataPath=Join-Path $dataPath "Data$projectSuffix"
    $appPath=Join-Path $appPath "App$projectSuffix"
}
$installToolPath=Join-Path ${env:ProgramFiles(x86)} "Trisoft\InstallTool"

$extensions=@(
    "*.asp"
    "*.js"
    "*.config"
    "*.xml"
    "*.xsl"
    "*.ps1"
    "*.psm1"
)

$foldersToScan=@(
    $installToolPath
    $webPath
    $dataPath
    $appPath
)

$replacementMatrix=@(

    # osuser. Change all derived parameters from baseurl
    @{
        CurrentValue=$deploymentParameters|Where-Object -Property Name -EQ osuser|Select-Object -ExpandProperty Value
        NewValue=$OsUserCredentials.UserName
    }
    # ospassword. Change all derived parameters from baseurl
    @{
        CurrentValue=$deploymentParameters|Where-Object -Property Name -EQ ospassword|Select-Object -ExpandProperty Value
        NewValue=$OsUserCredentials.GetNetworkCredential().Password
    }
    # basehostname. Change all derived parameters from baseurl
    @{
        CurrentValue=$deploymentParameters|Where-Object -Property Name -EQ basehostname|Select-Object -ExpandProperty Value
        NewValue=$HostName
    }
    # Certificate. Change all derived parameters from servicecertificatethumbprint
    @{
        CurrentValue=$deploymentParameters|Where-Object -Property Name -EQ servicecertificatethumbprint|Select-Object -ExpandProperty Value
        NewValue=$certificate.Thumbprint
    }
    # localservicehostname. Change all derived parameters from localservicehostname
    @{
        CurrentValue=$deploymentParameters|Where-Object -Property Name -EQ localservicehostname|Select-Object -ExpandProperty Value
        NewValue=$env:COMPUTERNAME
    }
    # machinename. Change all derived parameters from machinename
    @{
        CurrentValue=$deploymentParameters|Where-Object -Property Name -EQ machinename|Select-Object -ExpandProperty Value
        NewValue=$env:COMPUTERNAME
    }
    
    #TODO: Still need to check other files that connectstring and databasetype are found and add them to the extentions list
    # connectstring. Change all derived parameters from machinename
    @{
        CurrentValue=$deploymentParameters|Where-Object -Property Name -EQ connectstring|Select-Object -ExpandProperty Value
        NewValue=$ConnectionString
    }
    # databasetype. Change all derived parameters from machinename
    @{
        CurrentValue=$deploymentParameters|Where-Object -Property Name -EQ databasetype|Select-Object -ExpandProperty Value
        NewValue=$DbType
    }
)

Write-Verbose "Replacement matrix is:"

$foldersToScan |ForEach-Object {
    $blockName="Replacing files in $_"
    Write-Progress @scriptProgress -Status $blockName
    Write-Host $blockName

    $filePaths=Get-ChildItem -Path $_ -Include $extensions -Recurse -File|Select-Object -ExpandProperty FullName
    $filePaths|ForEach-Object {
        Write-Debug "Reading $_"
        $textInFile=[System.IO.File]::ReadAllText($_)
        $mustSaveFile=$false
        foreach($matrix in $replacementMatrix)
        {
            # Take no action if the values haven't changed
            if($matrix.CurrentValue -eq $matrix.NewValue)
            {
                continue
            }

            if($textInFile.IndexOf($matrix.CurrentValue, [System.StringComparison]::OrdinalIgnoreCase) -gt -1)
            {
                $textInFile=$textInFile.Replace($matrix.CurrentValue,$matrix.NewValue)
                $mustSaveFile=$true
            }
        }
        if($mustSaveFile)
        {
            [System.IO.File]::WriteAllText($_,$textInFile)
            Write-Verbose "Processed file $_"
        }
        else
        {
            Write-Verbose "No changes required for file $_"
        }
    }
}

#region TODO Additional files
<# 
osuser
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Setup\STS\ADFS\Scripts\SDL.ISH-ADFSv3.0-RP-Install.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\Author\ASP\IncParam.asp
[NOT] C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\__InstallTool\installplan.xml
[NOT] C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\__InstallTool\installplan.12.0.3215.1.Trisoft-DITA-OT.xml

ospassword
[NOT] C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\__InstallTool\installplan.xml
[NOT] C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\__InstallTool\installplan.12.0.3215.1.Trisoft-DITA-OT.xml

connectstring
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\Full-Export\full.export.xsl
[NOT] C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\__InstallTool\installplan.12.0.3215.1.Trisoft-DITA-OT.xml
[NOT] C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\__InstallTool\installplan.xml

databasetype
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Trisoft.Setup.DBUpgradeTool.Plan.xml
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\Author\ASP\IncParam.asp
[NOT] C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\__InstallTool\installplan.xml
[NOT] C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\__InstallTool\installplan.12.0.3215.1.Trisoft-DITA-OT.xml

localservicehostname

C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\PublishingService\Tools\FeedSDLLiveContent.ps1.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\PublishingService\Tools\Trisoft.InfoShare.Client.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Setup\STS\ADFS\Scripts\SDL.ISH-ADFSv3.0-RP-Install.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Setup\STS\ISHSTS\Scripts\Modules\InstallTool.psm1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\TranslationOrganizer\Bin\TranslationOrganizer.exe.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Utilities\SynchronizeToLiveContent\SynchronizeToLiveContent.ps1.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Utilities\SynchronizeToLiveContent\Trisoft.InfoShare.Client.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\Author\ASP\Trisoft.InfoShare.Client.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\Author\ASP\Web.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\InfoShareSTS\Configuration\infoShareSTS.config

baseurl
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDT3DXML.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDTDOCX.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDTJAR.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDTMP3.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDTMPG.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDTPPSX.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDTPPTX.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDTSMG.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDTSVG.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDTSVGZ.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDTSWF.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDTXLSX.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Create-EDTZIP.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\CreateEDT\Retrieve-EDT.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\Full-Export\full.export.xsl
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\Author\ASP\IncParam.asp
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\Author\ASP\Trisoft.InfoShare.Client.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\Author\ASP\Web.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\Author\ASP\Scripts\drag.js
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\InfoShareWS\connectionconfiguration.xml

basehostname
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\PublishingService\Tools\FeedSDLLiveContent.ps1.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Setup\STS\ADFS\Scripts\SDL.ISH-ADFSv3.0-RP-UnInstall.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Setup\STS\ADFS\Scripts\SDL.ISH-ADFSv3.0-RP-Install.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Setup\STS\ADFS\Scripts\SDL.ISH-ADFSv3.0-RP-UpdateCertificate.ps1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Setup\STS\ISHSTS\Scripts\Modules\InstallTool.psm1
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\TranslationOrganizer\Bin\TranslationOrganizer.exe.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Utilities\SynchronizeToLiveContent\SynchronizeToLiveContent.ps1.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\Author\ASP\Web.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\InfoShareSTS\Configuration\infoShareSTS.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\InfoShareWS\Web.config

machinename
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\BackgroundTask\Configuration\StartConsole.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Crawler\Configuration\RegisterThisCrawler.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Crawler\Configuration\StartConsole.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Crawler\Configuration\StartDataFolderCleanup.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Crawler\Configuration\StartReindex.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Crawler\Configuration\UnregisterAllCrawlers.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\TranslationBuilder\Configuration\StartConsole.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\TrisoftSolrLucene\Configuration\StartConsole.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\TrisoftSolrLucene\Configuration\StartOptimize.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\Utilities\DITA-OT\InfoShare\config.cmd
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\Full-Export\full.export.xsl
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\Full-Export\RunSetup.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\DatabaseIndependent\Examples\TestFields\RunSetup-AddTestFields.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\SQLServer2008\Tools\GrantComputerAccountPermissions.sql
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\SQLServer2012\Tools\GrantComputerAccountPermissions.sql
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Common\SQLServer2014\Tools\GrantComputerAccountPermissions.sql
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Dump\Oracle\expdp\expdp.par
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Dump\Oracle\export\export.par
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH1000To1001\RunSetup.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH1003To1004\RunAddEnrichUriConfigurationCard.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH100xTo1100\RunAddEditorTemplateDescrIconFields.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH100xTo1100\RunAddPluginConfigurationField.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH100xTo1100\RunAddTranslationJobAlias.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH100xTo1100\RunBackgroundTaskSetup.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH100xTo1100\RunSetPluginConfigurationFieldDefaultValue.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH1100To1101\ConfigurationCard_AddVersion.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH1100To1101\RunTransJob_Resolutions.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH110xTo1200\RunAddFishObjectActiveToEDT.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH110xTo1200\RunCorrectWorkflowFieldsOnTemplate.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH110xTo1200\RunCreateFISHEDTName.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH110xTo1200\RunExtensionSetup.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH1200To1201\RunAddTransJobLeasesField.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH35xTo360\RunSetup.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH35xTo360\RunSetupAddStandardStatuses.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH36xTo370\RunSetupLanguageIndependent.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH36xTo370\RunSetupPubOutput.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH37xTo380\RunSetup.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH386To387\RunSetup_SDLLiveContentIntegration.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH386To387\RunSetup_Webworks.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH38xTo900\RunSetup.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH38xTo900\RunSetupCorrectingMimeTypes.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH38xTo900\RunSetupUpdateEDTFileExtensions.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH38xTo900\RunSetup_PDF2plugin.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH38xTo900\RunSetup_SDLXPPIntegration.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH90xTo920\RunSetup-AddFishObjectActive.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH90xTo920\RunSetup-AddUserFields.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH90xTo920\RunSetup-CreateFISHSystemResolution.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH92xTo1000\RunLCUriConfigurationCard.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH92xTo1000\RunPublishVariableResolving.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH92xTo1000\RunSetupReviewDates.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH92xTo1000\RunSetupTransJob.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Database\Migration\DatabaseIndependent\ISH92xTo1000\RunSetupTransJob_ConfigurationCard.bat
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\Author\ASP\IncParam.asp
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\Author\ASP\Web.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\__InstallTool\installplan.12.0.3215.1.Trisoft-DITA-OT.xml
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\__InstallTool\installplan.xml

issuerwstrustendpointurl_normalized
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Applications\TranslationOrganizer\Bin\TranslationOrganizer.exe.config
C:\IshCD\12.0.1\20160815.CD.InfoShare.12.0.3215.1.Trisoft-DITA-OT\Websites\Author\ASP\Trisoft.InfoShare.Client.config
#>
#endregion

#endregion

#region 8. Start all processes

$blockName="Starting IIS application pools"
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

$ishAppPools| Start-WebAppPool
#endregion

Write-Separator -Invocation $MyInvocation -Footer
