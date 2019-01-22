[CmdletBinding(DefaultParameterSetName="OSUser")]  
param(
    [Parameter(Mandatory=$true,ParameterSetName="OSUserAndSqlUser")]
    [Parameter(Mandatory=$true,ParameterSetName="OSUser")]
    [string]$OSUserSqlUser,
    [Parameter(Mandatory=$true,ParameterSetName="OSUserAndSqlUser")]
    [Parameter(Mandatory=$true,ParameterSetName="SqlSUser")]
    [string]$SqlUserName,
    [Parameter(Mandatory=$true,ParameterSetName="OSUserAndSqlUser")]
    [Parameter(Mandatory=$true,ParameterSetName="SqlSUser")]
    [string]$SqlPassword
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
if(($PSCmdlet.ParameterSetName -eq "OSUser") -or ($PSCmdlet.ParameterSetName -eq "OSUserAndSqlUser"))
{
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
}

if(($PSCmdlet.ParameterSetName -eq "SqlUser") -or ($PSCmdlet.ParameterSetName -eq "OSUserAndSqlUser"))
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

Pop-Location -StackName SQL

Write-Separator -Invocation $MyInvocation -Footer
