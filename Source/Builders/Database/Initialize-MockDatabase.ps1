param(
    [Parameter(Mandatory=$true)]
    [string]$OSUserSqlUser,
    [Parameter(Mandatory=$false)]
    [string]$SqlUserName,
    [Parameter(Mandatory=$false)]
    [string]$SqlPassword
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

if((-not $SqlUserName -and $SqlPassword) -or ($SqlUserName -and -not $SqlPassword))
{
    Throw "Both parameters, 'SqlUserName' and 'SqlPassword' need to be provided if you also want to create a SQL User."
}

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
if($SqlUserName -and $SqlPassword)
{
Write-Host "[DEMO][SQL Server Express]:Configuring $SqlUserName account"

$sqlCmd = @"
USE [master]
GO
IF NOT EXISTS 
    (SELECT name  
     FROM sys.server_principals
     WHERE name = N'$SqlUserName')
BEGIN
    SELECT N'Creating login for: $SqlUserName'
    CREATE LOGIN [$SqlUserName] WITH PASSWORD = N'$SqlPassword', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF, DEFAULT_DATABASE=[$dbName]
END
ELSE
BEGIN
    SELECT N'Altering login for: $SqlUserName'
    ALTER LOGIN [$SqlUserName] WITH PASSWORD = N'$SqlPassword', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF, DEFAULT_DATABASE=[$dbName]
END
GO
ALTER LOGIN [$SqlUserName] ENABLE;
GO
EXEC master..sp_addsrvrolemember @loginame = N'$SqlUserName', @rolename = N'sysadmin'
GO
USE [$dbName]
GO
IF NOT EXISTS (SELECT name 
                FROM sys.database_principals
                WHERE type = 'S' AND name = N'$SqlUserName')
BEGIN
    SELECT N'Creating user for: $SqlUserName'
    CREATE USER [$SqlUserName] FOR LOGIN [$SqlUserName] WITH DEFAULT_SCHEMA=[dbo]
END
ELSE
BEGIN
    SELECT N'User already exists: $SqlUserName'
END
GO
USE [$dbName]
GO
ALTER USER [$SqlUserName] WITH DEFAULT_SCHEMA=[dbo]
GO
USE [$dbName]
GO
ALTER ROLE [db_owner] ADD MEMBER [$SqlUserName]
GO
"@

Invoke-Sqlcmd -Query $sqlCmd
}
else
{
    #Throw (or is logging a warning enough?)
    throw "Both parameters SqlUserName and SqlPassword need to be provided."
}
Pop-Location -StackName SQL

Write-Separator -Invocation $MyInvocation -Footer
