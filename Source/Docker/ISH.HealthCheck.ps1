param(
    [Parameter(Mandatory=$false)]
    [switch]$IncludeMSSQL=$false
)

if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$serviceNames=@(
    "W3SVC"        
)

if($IncludeMSSQL)
{
    $serviceNames+="MSSQL`$SQLEXPRESS"
}

$serviceNames|ForEach-Object {
    $service=Get-Service -Name $_
    if($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running)
    {
        Write-Host "$_ is not running"
        exit -1
    }
}

exit 0