param(
    [Parameter(Mandatory=$true,ParameterSetName="Database")]
    [ValidateSet("12.0.3","12.0.4","13.0.0")]
    [string]$ISHVersion="12.0.3"
)

$rootfolder = "C:\Windows\Temp"

$sql_express_download_url="https://download.microsoft.com/download/2/A/5/2A5260C3-4143-47D8-9823-E91BB0121F94/SQLEXPR_x64_ENU.exe"
$sqlExpressPath=Join-Path $rootfolder "sqlexpress.exe"
$setupPath=Join-Path $rootfolder "setup\setup.exe"
$extractPath=Join-Path $rootfolder "setup"
Write-Host "Downloading"
Invoke-WebRequest -Uri $sql_express_download_url -OutFile $sqlExpressPath

Write-Host "Extracting"
Start-Process -Wait -FilePath $sqlExpressPath -ArgumentList /qs, /x:`"$extractPath`"

Write-Host "Installing"
& $setupPath /q /ACTION=Install /INSTANCENAME=SQLEXPRESS /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS
Write-Host "Installed"

Write-Host "Stopping Service"
stop-service MSSQL`$SQLEXPRESS

Write-Host "Set sql server express to use static TCP port 1433"
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql12.SQLEXPRESS\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpdynamicports -value ''
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql12.SQLEXPRESS\mssqlserver\supersocketnetlib\tcp\ipall' -name tcpport -value 1433
set-itemproperty -path 'HKLM:\software\microsoft\microsoft sql server\mssql12.SQLEXPRESS\mssqlserver\' -name LoginMode -value 2

Write-Host "Starting Service"
start-service MSSQL`$SQLEXPRESS

Write-Host "Cleaning"
Remove-Item -Recurse -Force $sqlExpressPath, $setupPath

