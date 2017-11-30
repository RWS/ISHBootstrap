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
    Write-Host "Probing service $_"
    $service=Get-Service -Name $_
    Write-Host "Service $_ status is $($service.Status)"
    if($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running)
    {
        Write-Host "[DockerHost]$_ is not running"
        Write-Host "[DockerHost]Not healthy"
        exit 1
    }
}
Write-Host "[DockerHost]Healthy"
exit 0