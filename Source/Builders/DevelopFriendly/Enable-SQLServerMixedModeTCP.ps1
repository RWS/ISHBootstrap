# Inspired by container docker file https://github.com/Microsoft/sql-server-samples/blob/master/samples/manage/windows-containers/mssql-server-2016-express-sp1-windows/dockerfile

param(

)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

Write-Information "[DEVELOPFRIENDLY][SQL Server Express]:Enabling Mixed mode authentication and TCP protocol for external connections"

$sqlExpressServiceName="MSSQL`$SQLEXPRESS"
Stop-Service -Name $sqlExpressServiceName

Set-ItemProperty -Path "HKLM:\software\microsoft\microsoft sql server\mssql$sqlServerMajorVersion.SQLEXPRESS\mssqlserver\supersocketnetlib\tcp" -Name Enabled -Value '1'
Set-ItemProperty -Path "HKLM:\software\microsoft\microsoft sql server\mssql$sqlServerMajorVersion.SQLEXPRESS\mssqlserver\supersocketnetlib\tcp\ipall" -Name tcpdynamicports -Value ''
Set-ItemProperty -Path "HKLM:\software\microsoft\microsoft sql server\mssql$sqlServerMajorVersion.SQLEXPRESS\mssqlserver\supersocketnetlib\tcp\ipall" -Name tcpport -Value 1433
Set-ItemProperty -Path "HKLM:\software\microsoft\microsoft sql server\mssql$sqlServerMajorVersion.SQLEXPRESS\mssqlserver\" -Name LoginMode -Value 2
$null=New-NetFirewallRule -DisplayName "SQL Server (1433)" -Direction Inbound -Action Allow -LocalPort @("1433") -Protocol TCP
Start-Service -Name $sqlExpressServiceName
    
Write-Warning "[DEVELOPFRIENDLY][SQL Server Express]:Enabled Mixed mode authentication and TCP protocol for external connections"

Write-Separator -Invocation $MyInvocation -Footer
