param(
    [Parameter(Mandatory=$true,ParameterSetName="Database")]
    [ValidateSet("12.0.3","12.0.4","13.0.0","13.0.1","13.0.2","14.0.0")]
    [string]$ISHVersion
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

$sql_express_2014_download_url="https://download.microsoft.com/download/E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB/Express%2064BIT/SQLEXPR_x64_ENU.exe"
$sql_express_2016_download_url="https://download.microsoft.com/download/2/A/5/2A5260C3-4143-47D8-9823-E91BB0121F94/SQLEXPR_x64_ENU.exe"
$sql_express_2017_download_url="https://download.microsoft.com/download/2/A/5/2A5260C3-4143-47D8-9823-E91BB0121F94/SQLEXPR_x64_ENU.exe"

$sql_express_download_url= $sql_express_2017_download_url

switch -regex ($ISHVersion) {
    '12.0.3|12.0.4' {$sql_express_download_url= $sql_express_2014_download_url}
    '13.0.0|13.0.1' {$sql_express_download_url= $sql_express_2016_download_url}
    '13.0.2|14.0.0' {$sql_express_download_url= $sql_express_2017_download_url}
    default         {$sql_express_download_url= $sql_express_2017_download_url}
}
$sqlExpressPath=Join-Path $PSScriptRoot "sqlexpress.exe"
$setupPath=Join-Path $PSScriptRoot "setup\setup.exe"
$extractPath=Join-Path $PSScriptRoot "setup"
Write-Host "Downloading"
Invoke-WebRequest -Uri $sql_express_download_url -OutFile $sqlExpressPath

Write-Host "Extracting"
Start-Process -Wait -FilePath $sqlExpressPath -ArgumentList /qs, /x:`"$extractPath`"

Write-Host "Installing"
& $setupPath /q /ACTION=Install /INSTANCENAME=SQLEXPRESS /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS

Write-Host "Cleaning"
Remove-Item -Recurse -Force $sqlExpressPath, $setupPath

Write-Separator -Invocation $MyInvocation -Footer
