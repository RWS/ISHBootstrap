param(
    
)
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

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
$cmd="select serverproperty('ServerName') AS ServerName"
$result=Invoke-Sqlcmd -Query $cmd
$serverName=$result.ServerName
Pop-Location -StackName "SQL"
#endregion

#region 2. Build connection string
$dbName="InfoShare"
"Provider=MSOLEDBSQL.1;Integrated Security=SSPI;Persist Security Info=False;Initial Catalog=$dbName;Data Source=$serverName"
#endregion


Write-Separator -Invocation $MyInvocation -Footer