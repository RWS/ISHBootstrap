. $PSScriptRoot\Invoke-CommandWrap.ps1

Function Add-ModuleFromRemote {
    param (
        [Parameter(Mandatory=$true,ParameterSetName="Computer")]
        [AllowNull()]
        $ComputerName=$null,
        [Parameter(Mandatory=$false,ParameterSetName="Computer")]
        [pscredential]$Credential=$null,
        [Parameter(Mandatory=$true,ParameterSetName="Session")]
        [AllowNull()]
        $Session,
        [Parameter(Mandatory=$true,ParameterSetName="Local")]
        [Parameter(Mandatory=$true,ParameterSetName="Computer")]
        [Parameter(Mandatory=$true,ParameterSetName="Session")]
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
            if($Credential)
            {
                $Session=New-PSSession -ComputerName $ComputerName -Credential $credential
            }
            else
            {
                $Session=New-PSSession -ComputerName $ComputerName
            }
            $undoHash.Session=$Session
            Invoke-CommandWrap -Session $session -BlockName "Initialize Debug/Verbose preference on $($Session.ComputerName)" -ScriptBlock {}
        }

        Write-Debug "Targetting remote session $($Session.ComputerName)"
        Write-Verbose "[$BlockName] Begin on $($Session.ComputerName)"
        $Name | ForEach-Object { 
            Write-Debug "Import module $_ from $($Session.ComputerName)"
            if($Session)
            {
                Import-Module -Name $_ -PSSession $Session -Force
            }
            else
            {
                Import-Module -Name $_ -Force
            }
            Write-Verbose "Imported module $_ from $($Session.ComputerName)"
        }
    }

    finally
    {
        New-Object PSObject -Property $undoHash
    }
}