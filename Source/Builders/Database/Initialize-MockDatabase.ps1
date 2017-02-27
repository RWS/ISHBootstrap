param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("12.0.3","12.0.4","13.0.0")]
    [string]$ISHVersion,
    [Parameter(Mandatory=$false)]
    [switch]$DevelopFriendly=$false
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

$ishServerVersion=($ISHVersion -split "\.")[0]
$ishRevision=($ISHVersion -split "\.")[2]

$sqlServerItem=Get-ChildItem -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server" -Filter "*0" |Sort-Object -Descending @{expression={[int]$_.Name}}| Select-Object -First 1
$sqlServerPath=$sqlServerItem |Select-Object -ExpandProperty FullName
$sqlServerMajorVersion=$sqlServerItem.Name.Substring(0,$sqlServerItem.Name.Length-1)

#region 1. [DEVELOPFRIENDLY] Enable TCP remote connections and mixed mode authentication
if($DevelopFriendly)
{
    & ..\DevelopFriendly\Enable-SQLServerMixedModeTCP.ps1
}
#endregion

#region 2. Import SQLPS module

# Test if SQLPS module is already available.
# Normally the installer modifies the system variables $env:PSModulePath but for them to take effect a restart is needed.
Write-Information "Importing module SQLPS"    
if(-not (Get-Module SQLPS -ListAvailable))
{
    Import-Module "$sqlServerPath\Tools\PowerShell\Modules\SQLPS\SQLPS.PSD1" -Force
}
else
{
    Import-Module SQLPS -Force
}

#endregion

#region 3. [DEVELOPFRIENDLY] Alter sa password

if($DevelopFriendly)
{
    $blockName="[DEVELOPFRIENDLY][SQL Server Express]:Enabling sa account"
    Write-Progress @scriptProgress -Status $blockName
    Write-Information $blockName

    $sa_password="Password123"
    $sqlAlterSACmd = "ALTER LOGIN sa with password=" +"'" + $sa_password + "'" + ";ALTER LOGIN sa ENABLE;"

    Invoke-Sqlcmd -Query $sqlAlterSACmd -ServerInstance ".\SQLEXPRESS" 
    Set-Location c:
    Write-Warning "[DEVELOPFRIENDLY][SQL Server Express]:Enabled sa account"
}

#endregion

#region 4. Restore database
$blockName="Restoring ISH database"
Write-Progress @scriptProgress -Status $blockName
Write-Information $blockName

$ishCDPath=Get-ISHCD -ListAvailable |
    Where-Object -Property Major -EQ $ishServerVersion |
    Where-Object -Property Revision -EQ $ishRevision|
    Where-Object -Property IsExpanded -EQ $true |
    Select-Object -ExpandProperty ExpandedPath

$segments=@(
    $ishCDPath
    "Database"
    "Dump"
    "SQLServer2012"
    "20151116.InfoShareEmpty-12.0.0-sqlserver2012.isource.InfoShare-OasisDita.1.2.bak"
)
$infoShareBakPath=$segments -join '\'
$sqlServerDataPath="C:\Program Files\Microsoft SQL Server\MSSQL$sqlServerMajorVersion.SQLEXPRESS\MSSQL\DATA"
$dbName="InfoShare"
$sqlRestoreDBCmd=@"
USE [master]
if db_id('$dbName') is null
BEGIN
RESTORE DATABASE [$dbName] FROM  DISK = N'$infoShareBakPath' WITH  FILE = 1,  MOVE N'$dbName' TO N'$sqlServerDataPath\$dbName.mdf',  MOVE N'$($dbName)_Log' TO N'$sqlServerDataPath\$($dbName)_log.ldf',  NOUNLOAD,  STATS = 5
END
GO
"@
Invoke-Sqlcmd -Query $sqlRestoreDBCmd -ServerInstance ".\SQLEXPRESS" 

Set-Location c:

#endregion

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
