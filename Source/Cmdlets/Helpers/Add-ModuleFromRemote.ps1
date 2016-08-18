. $PSScriptRoot\Invoke-CommandWrap.ps1

Function Add-ModuleFromRemote {
    param (
        [Parameter(Mandatory=$true,ParameterSetName="Computer")]
        $ComputerName,
        [Parameter(Mandatory=$true,ParameterSetName="Session")]
        $Session,
        [Parameter(Mandatory=$true)]
        [string[]]$Name
    ) 

    try 
    {
        $undoHash=@{
            Session=$null
            Module=$Name
        }
        if($ComputerName)
        {
            $Session=New-PSSession -ComputerName $ComputerName
            $undoHash.Session=$Session
            Invoke-CommandWrap -Session $session -BlockName "Initialize Debug/Verbose preference on $($Session.ComputerName)" -ScriptBlock {}
        }

        Write-Debug "Targetting remote session $($Session.ComputerName)"
        Write-Verbose "[$BlockName] Begin on $($Session.ComputerName)"
        $Name | ForEach-Object { 
            Write-Verbose "Import module $_ from $($Session.ComputerName)"
            Import-Module -Name $_ -PSSession $Session -Force
            Write-Host "Imported module $_ from $($Session.ComputerName)"
        }
    }

    finally
    {
        New-Object PSObject -Property $undoHash
    }
}