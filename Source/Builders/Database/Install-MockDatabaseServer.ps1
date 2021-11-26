param(
    [Parameter(Mandatory=$true,ParameterSetName="Database")]
    [ValidateSet("12.0.3","12.0.4","13.0.0","13.0.1","13.0.2","14.0.0","14.0.1","14.0.2","14.0.3","14.0.4","15.0.0")]
    [string]$ISHVersion,
    [Parameter(Mandatory=$false,ParameterSetName="Database")]
    [string]$MockConnectionString=$null
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header
# Normalize to null incase the packer and container feed the parameter with empty
if($MockConnectionString -eq "")
{
    $MockConnectionString=""
}

$mockDatabase=-not $MockConnectionString

if($mockDatabase)
{
    $sql_express_2014_download_url="https://download.microsoft.com/download/E/A/E/EAE6F7FC-767A-4038-A954-49B8B05D04EB/Express%2064BIT/SQLEXPR_x64_ENU.exe"
    $sql_express_2016_download_url="https://download.microsoft.com/download/2/A/5/2A5260C3-4143-47D8-9823-E91BB0121F94/SQLEXPR_x64_ENU.exe"
    $sql_express_2017_download_url="https://go.microsoft.com/fwlink/?linkid=829176"

    $sql_express_download_url= $sql_express_2017_download_url

    switch -regex ($ISHVersion) {
        '12.0.3|12.0.4' {$sql_express_download_url= $sql_express_2014_download_url}
        '13.0.0|13.0.1' {$sql_express_download_url= $sql_express_2016_download_url}
        '13.0.2|14.0.0|14.0.1|14.0.2|14.0.3|14.0.4|15.0.0' {$sql_express_download_url= $sql_express_2017_download_url}
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
    & $setupPath /q /ACTION=Install /INSTANCENAME=ISHSQLEXPRESS /FEATURES=SQLEngine /UPDATEENABLED=0 /SQLSVCACCOUNT='NT AUTHORITY\System' /SQLSYSADMINACCOUNTS='BUILTIN\ADMINISTRATORS' /TCPENABLED=1 /NPENABLED=0 /IACCEPTSQLSERVERLICENSETERMS

    Write-Host "Cleaning"
    Remove-Item -Recurse -Force $sqlExpressPath, $setupPath

    # Configure tcp settings and login mode for ISHSQLEXPRESS
    Write-Host "Configuring tcp settings and login mode for ISHSQLEXPRESS" 
    Stop-Service MSSQL`$ISHSQLEXPRESS
    Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql1*.ISHSQLEXPRESS/mssqlserver/supersocketnetlib/tcp' -Name Enabled -Value '1'
    Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql1*.ISHSQLEXPRESS/mssqlserver/supersocketnetlib/tcp/ipall' -Name tcpdynamicports -Value ''
    Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql1*.ISHSQLEXPRESS/mssqlserver/supersocketnetlib/tcp/ipall' -Name tcpport -Value 1433
    Set-ItemProperty -Path 'HKLM:\software\microsoft\microsoft sql server\mssql1*.ISHSQLEXPRESS/mssqlserver/' -Name LoginMode -Value 2
    Start-Service MSSQL`$ISHSQLEXPRESS  
}
else
{
    Write-Warning "Skipping installation of SQL Server Express. No 'MockConnectionString' provided" 
}

Write-Separator -Invocation $MyInvocation -Footer
