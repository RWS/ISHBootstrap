param(
    [Parameter(Mandatory=$true,ParameterSetName="Database")]
    [ValidateSet("12.0.3","12.0.4","13.0.0")]
    [string]$ISHVersion
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

$sql_express_download_url="https://download.microsoft.com/download/2/A/5/2A5260C3-4143-47D8-9823-E91BB0121F94/SQLEXPR_x64_ENU.exe"
$sqlExpressPath=Join-Path $PSScriptRoot "sqlexpress.exe"
$setupPath=Join-Path $PSScriptRoot "setup\setup.exe"
Write-Host "Downloading"
Invoke-WebRequest -Uri $sql_express_download_url -OutFile $sqlExpressPath

Write-Host "Extracting"
Start-Process -Wait -FilePath $sqlExpressPath -ArgumentList /qs, /x:setup

Write-Host "Installing"
& $setupPath /q /ACTION=Install /INSTANCENAME=SQLEXPRESS /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS

Write-Host "Cleaning"
Remove-Item -Recurse -Force $sqlExpressPath, $setupPath

Write-Separator -Invocation $MyInvocation -Footer