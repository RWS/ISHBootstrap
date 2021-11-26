param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("12.0.3","12.0.4","13.0.0","13.0.1","13.0.2","14.0.0","14.0.1","14.0.2","14.0.3","14.0.4","15.0.0")]
    [string]$ISHVersion,
    [Parameter(Mandatory=$false)]
    [switch]$EmptyDB
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

Push-Location -StackName "SQL"

#region 1. Import SQLPS module

# Test if SQLPS module is already available.
# Normally the installer modifies the system variables $env:PSModulePath but for them to take effect a restart is needed.
Write-Host "Importing module SQLPS"    
if(-not (Get-Module SQLPS -ListAvailable))
{
    Import-Module "$sqlServerPath\Tools\PowerShell\Modules\SQLPS\SQLPS.PSD1" -Force
}
else
{
    Import-Module SQLPS -Force
}
Get-ChildItem |Where-Object -Property Description -EQ "SQL Server Database Engine"|Select-Object -First 1|Get-ChildItem|Get-ChildItem|Push-Location
$cmd="select serverproperty('InstanceDefaultDataPath') AS InstanceDefaultDataPath,serverproperty('InstanceDefaultLogPath') AS InstanceDefaultLogPath"
$result=Invoke-Sqlcmd -Query $cmd
$sqlServerDataPath=$result.InstanceDefaultDataPath.TrimEnd("\")
$sqlServerLogPath=$result.InstanceDefaultLogPath.TrimEnd("\")
#endregion

#region 2. Restore database
$blockName="Restoring ISH database"
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

$ishCDPath=Get-ISHCD -ListAvailable |
    Where-Object -Property Major -EQ $ishServerVersion |
    Where-Object -Property Revision -EQ $ishRevision|
    Where-Object -Property IsExpanded -EQ $true |
    Select-Object -ExpandProperty ExpandedPath
$ishCDPath
$segments=@(
    $ishCDPath
    "Database"
    "Dump"
    "SQLServer*"
)

if ($EmptyDB.IsPresent)
{
    $segments+=@("*ISHEmpty*.bak")
}
else
{
    $segments+=@("*ISHDemo*.bak")
}

$infoShareBakPath=$segments -join '\'
$infoShareBakPath=Resolve-Path $infoShareBakPath

$dbName="InfoShare"
$sqlRestoreDBCmd=@"
USE [master]
if db_id('$dbName') is null
BEGIN
RESTORE DATABASE [$dbName] FROM  DISK = N'$infoShareBakPath' WITH  FILE = 1,  MOVE N'$dbName' TO N'$sqlServerDataPath\$dbName.mdf',  MOVE N'$($dbName)_Log' TO N'$sqlServerLogPath\$($dbName)_log.ldf',  NOUNLOAD,  STATS = 5
END
GO
"@

Invoke-Sqlcmd -Query $sqlRestoreDBCmd 

Pop-Location -StackName "SQL"

#endregion

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
