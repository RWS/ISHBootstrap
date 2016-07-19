param (
    [Parameter(Mandatory=$true)]
    [string[]]$Computer
) 
    
. "$PSScriptRoot\..\..\Cmdlets\Helpers\Invoke-CommandWrap.ps1"
Write-Verbose "Restarting $Computer"
Restart-Computer -ComputerName  $Computer -Force
Write-Host "Initiated $Computer restart"

$testBlock = {
    Write-Host "$($env:COMPUTERNAME) is alive"
}

    
do {
    $sleepSeconds=5
    Write-Debug "Sleeping for $sleepSeconds seconds"
    Start-Sleep -Seconds $sleepSeconds
    
    Write-Verbose "Testing $Computer"

    $areAlive=$true
    Write-Debug "Invoking Test-Connection for $Computer"
    Test-Connection $Computer -Quiet | ForEach-Object {
        if(-not $_)
        {
            $areAlive=$false
        }
    }
    if(-not $areAlive)
    {
        Write-Warning "Failed Test-Connection for $Computer"
        continue
    }
    try
    {
        Write-Debug "Invoking powershell remote for $Computer"
        Invoke-Command -ComputerName $Computer -ScriptBlock $testBlock -ErrorVariable $errorVariable -ErrorAction Stop
    }
    catch
    {
        Write-Warning "Failed powershell remote for $Computer"
        $areAlive=$false
    }

}while(-not $areAlive)

Write-Host "$Computer is back online"
