param(
    [Parameter(Mandatory=$true)]
    [string]$OSUserSqlUser
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header


$sqlServerItem=Get-ChildItem -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server" -Filter "*0" |Sort-Object -Descending @{expression={[int]$_.Name}}| Select-Object -First 1
$sqlServerPath=$sqlServerItem |Select-Object -ExpandProperty FullName
$sqlServerMajorVersion=$sqlServerItem.Name.Substring(0,$sqlServerItem.Name.Length-1)

Push-Location -StackName "SQL"

Write-Host "Importing module SQLPS"    
if(-not (Get-Module SQLPS -ListAvailable))
{
    $sqlServerItem=Get-ChildItem -Path "${env:ProgramFiles(x86)}\Microsoft SQL Server" -Filter "*0" |Sort-Object -Descending @{expression={[int]$_.Name}}| Select-Object -First 1
    $sqlServerPath=$sqlServerItem |Select-Object -ExpandProperty FullName
    Import-Module "$sqlServerPath\Tools\PowerShell\Modules\SQLPS\SQLPS.PSD1" -Force
}
else
{
    Import-Module SQLPS -Force
}

$demoConnectionString=Get-ISHDeploymentParameters|Where-Object -Property Name -EQ connectstring|Select-Object -ExpandProperty Value
$regEx=".+;Initial Catalog=(?<dbname>[a-zA-Z0-9]+);*"
if($demoConnectionString -match $regEx)
{
    $dbName=$Matches["dbname"]
}
else
{
    throw "Could not parse connection string"
}
Write-Host "[DEMO][SQL Server Express]:Configuring $OSUserSqlUser account"

$sqlCmd = @"
USE [master]
GO
CREATE LOGIN [$OSUserSqlUser] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
GO
USE [$dbName]
GO
CREATE USER [$osUserSqlUser] FOR LOGIN [$osUserSqlUser]
GO
USE [$dbName]
GO
ALTER USER [$osUserSqlUser] WITH DEFAULT_SCHEMA=[dbo]
GO
USE [$dbName]
GO
ALTER ROLE [db_owner] ADD MEMBER [$OSUserSqlUser]
GO
"@

Invoke-Sqlcmd -Query $sqlCmd
Pop-Location -StackName SQL

Write-Separator -Invocation $MyInvocation -Footer