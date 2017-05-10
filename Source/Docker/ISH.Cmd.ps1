param(
    [Parameter(Mandatory=$true,ParameterSetName="External Database")]
    [Parameter(Mandatory=$true,ParameterSetName="Internal Database")]
    [string]$OsUserName,
    [Parameter(Mandatory=$true,ParameterSetName="External Database")]
    [Parameter(Mandatory=$true,ParameterSetName="Internal Database")]
    [string]$OsUserPassword,
    [Parameter(Mandatory=$true,ParameterSetName="External Database")]
    [Parameter(Mandatory=$true,ParameterSetName="Internal Database")]
    [string]$PFXCertificatePath,
    [Parameter(Mandatory=$true,ParameterSetName="External Database")]
    [Parameter(Mandatory=$true,ParameterSetName="Internal Database")]
    [string]$PFXCertificatePassword,
    [Parameter(Mandatory=$false,ParameterSetName="External Database")]
    [Parameter(Mandatory=$false,ParameterSetName="Internal Database")]
    [string]$HostName=$null,
    [Parameter(Mandatory=$true,ParameterSetName="External Database")]
    [string]$ConnectionString,
    [Parameter(Mandatory=$true,ParameterSetName="External Database")]
    [ValidateSet("sqlserver2014","oracle")]
    [string]$DBType,
    [Parameter(Mandatory=$false,ParameterSetName="Internal Database")]
    [string]$sa_password,
    [Parameter(Mandatory=$false,ParameterSetName="Internal Database")]
    [string]$ACCEPT_EULA,
    [Parameter(Mandatory=$false,ParameterSetName="External Database")]
    [Parameter(Mandatory=$false,ParameterSetName="Internal Database")]
    [switch]$Loop=$false
)

if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$buildersPath=Join-Path $PSScriptRoot "..\Builders"

$osUserCredentials=New-Object System.Management.Automation.PSCredential($OsUserName, (ConvertTo-SecureString -String $OsUserPassword -AsPlainText -Force))
$osUserCredentials=Get-ISHNormalizedCredential -Credentials $osUserCredentials
$pfxCertificateSecurePassword=ConvertTo-SecureString -String $PFXCertificatePassword -AsPlainText -Force

$hash=@{
    OsUserCredentials=$osUserCredentials
    PFXCertificatePath=$PFXCertificatePath
    PFXCertificatePassword=$pfxCertificateSecurePassword
}

if($HostName)
{
    $hash.HostName=$HostName
}

switch ($PSCmdlet.ParameterSetName)
{
    'External Database' {
        $hash.ConnectionString=$ConnectionString
        $hash.DbType=$DBType
    }
    'Internal Database' {
        Write-Host "Starting internal database"
        # Doing part of the https://github.com/Sarafian/Docker/blob/master/Source/mssql2014-server-windows-express/start.ps1

        if($ACCEPT_EULA -ne "Y" -And $ACCEPT_EULA -ne "y"){
	        Write-Verbose "ERROR: You must accept the End User License Agreement before this container can start."
	        Write-Verbose "Set the environment variable ACCEPT_EULA to 'Y' if you accept the agreement."

            exit 1 
        }

        Write-Verbose "Starting SQL Server"
        start-service MSSQL`$SQLEXPRESS

        if($sa_password -ne "_"){
	        Write-Verbose "Changing SA login credentials"
            $sqlcmd = "ALTER LOGIN sa with password=" +"'" + $sa_password + "'" + ";ALTER LOGIN sa ENABLE;"
            Invoke-Sqlcmd -Query $sqlcmd -ServerInstance ".\SQLEXPRESS" 
        }

        Write-Verbose "Started SQL Server."
    }
}

& $buildersPath\Initialize-ISH.Instance.ps1 @hash -InContainer

if($Loop)
{
    $lastCheck = (Get-Date).AddSeconds(-2) 
    while ($true) { 
        if($PSCmdlet.ParameterSetName -eq "Internal Database")
        {
            Get-EventLog -LogName Application -Source "MSSQL*" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message	 
        }
        # TODO: Figure out ISH event log source
        Get-EventLog -LogName Application -Source "Trisoft*" -After $lastCheck | Select-Object TimeGenerated, EntryType, Message	 

        $lastCheck = Get-Date 
        Start-Sleep -Seconds 2 
    }
}
else
{
    Write-Host "hostname=$HostName"
}