. $PSScriptRoot\Invoke-CommandWrap.ps1

Function Invoke-ImplicitRemoting {
    param (
        [Parameter(Mandatory=$true)]
        $ScriptBlock,
        [Parameter(Mandatory=$true)]
        $BlockName,
        [Parameter(Mandatory=$false)]
        $ComputerName=$null,
        [Parameter(Mandatory=$false)]
        $Session=$null,
        [Parameter(Mandatory=$true)]
        $ImportModule
    ) 

    if($Session -and $ComputerName)
    {
        throw "Cannot process both ComputerName and Session"
    }
    try 
    {
        $isRemote=$ComputerName -or $Session
        if($ComputerName)
        {
            $Session=New-PSSession -ComputerName $ComputerName
            Invoke-CommandWrap -Session $session -BlockName "Initialize Debug/Verbose preference on session" -ScriptBlock {}
        }

        if($isRemote)
        {
            Write-Debug "Targetting remote session $($Session.ComputerName)"
            Write-Verbose "[$BlockName] Begin on $($Session.ComputerName)"
            $ImportModule | ForEach-Object { 
                Write-Verbose "Import module $_ from $($Session.ComputerName)"
                Import-Module -Name $_ -PSSession $Session -Force
                Write-Host "Imported module $_ from $($Session.ComputerName)"
            }
        }
        else
        {
            Write-Debug "Targetting local"
            Write-Verbose "[$BlockName] Begin local"
            $ImportModule | ForEach-Object { 
                Write-Verbose "Import module $_"
                Import-Module -Name $_ -Force
                Write-Host "Imported module $_"
            }
        }
        Invoke-Command -ScriptBlock $ScriptBlock
    }

    finally
    {
        $ImportModule | ForEach-Object { 
            Get-Module -Name $_| Remove-Module
        }
        Write-Host "Removed module $ImportModule"

        if($isRemote)
        {
            Write-Host "[$BlockName] Finish on $($session.ComputerName)"
        }
        else
        {
            Write-Host "[$BlockName] Finish local"
        }

        if($ComputerName)
        {
            $Session|Remove-PSSession
        }

    }
}