<#
    .SYNOPSIS
        Wraps the Invoke-Command to seamlessy execute script blocks remote or local
    .DESCRIPTION
        Invoke-Command does not provide a transparent method to execute script blocks locally or remotely without conditions. This limited wrapper commandlet does this.
        Every blocked is wrapped with logging statements
    .PARAMETER  ScriptBlock
        The script block
    .PARAMETER  BlockName
        Name of the block. This is for logging purposes.
    .PARAMETER  ArgumentList
        Arguments for the script block.
    .PARAMETER  Computer
        Target computer
    .PARAMETER  Session
        Target session
    .PARAMETER  UseParameters
        An array of variable names that we expect to be available
    .EXAMPLE
        $block={
            param($Message)
            Write-Host "$($env:COMPUTERNAME) says $Message"
        }
        Invoke-CommandWrap -ComputerName @("EXAMPLE01","EXAMPLE02") -BlockName "Saying hello" -ScriptBlock $block -ArgumentList "Hello"

        VERBOSE: [Saying hello] Begin on EXAMPLE01 EXAMPLE02
        EXAMPLE01 says Hello
        EXAMPLE02 says Hello
        VERBOSE: [Saying hello] Finish on EXAMPLE01 EXAMPLE02

    .EXAMPLE
        $block={
            param($Message)
            Write-Host "$($env:COMPUTERNAME) says $Message"
        }
        $session=@("EXAMPLE01","EXAMPLE01")|New-PSSession
        Invoke-CommandWrap -Session $session -BlockName "Saying hello" -ScriptBlock $block -ArgumentList "Hello"

        VERBOSE: [Saying hello] Begin on EXAMPLE02 EXAMPLE01
        EXAMPLE02 says Hello
        EXAMPLE01 says Hello
        VERBOSE: [Saying hello] Finish on EXAMPLE02 EXAMPLE01

    .EXAMPLE
        $block={
            param($Message)
            Write-Host "$($env:COMPUTERNAME) says $Message"
        }
        Invoke-CommandWrap -BlockName "Saying hello" -ScriptBlock $block -ArgumentList "Hello"

        VERBOSE: [Saying hello] Begin local
        LOCALHOST says Hello
        VERBOSE: [Saying hello] Finish local

    .EXAMPLE
        $block= {
            #When executing remotely a block the $DebugPreference and $VerbosePreference are not copies. Also internal variables will not be available
            Write-Debug "internal=$internal"
            Write-Verbose "internal=$internal"
            Write-Host "internal=$internal"
        }
        Invoke-CommandWrap -BlockName "Improve remoting" -ScriptBlock $block -ComputerName EXAMPLE01

        VERBOSE: [Improve remoting] Begin EXAMPLE01
        DEBUG: internal=
        VERBOSE: internal=
        HOST: internal=
        VERBOSE: [Improve remoting] Finish EXAMPLE01

    .EXAMPLE
        $block= {
            #When executing remotely a block the $DebugPreference and $VerbosePreference are not copies. Also internal variables will not be available
            Write-Debug "internal=$internal"
            Write-Verbose "internal=$internal"
            Write-Host "internal=$internal"
        }
        $internal="Value1"
        Invoke-CommandWrap -BlockName "Improve remoting" -ScriptBlock $block -ComputerName EXAMPLE01 -UseParameters @("internal")

        VERBOSE: [Improve remoting] Begin EXAMPLE01
        DEBUG: internal=Value1
        VERBOSE: internal=Value1
        HOST: internal=Value1
        VERBOSE: [Improve remoting] Finish EXAMPLE01

    .LINK
        Invoke-Command
#>
Function Invoke-CommandWrap {
    param (
        [Parameter(Mandatory=$true)]
        $ScriptBlock,
        [Parameter(Mandatory=$true)]
        $BlockName,
        [Parameter(Mandatory=$false)]
        $ArgumentList=$null,
        [Parameter(Mandatory=$false)]
        $ComputerName=$null,
        [Parameter(Mandatory=$false)]
        $Session=$null,
        [Parameter(Mandatory=$false)]
        [string[]]$UseParameters=$null
    ) 

    if($Session -and $ComputerName)
    {
        throw "Cannot process both ComputerName and Session"
    }

    if($Session -or $ComputerName)
    {
        $scriptSegments=@()
        $scriptSegments += {
            if($PSSenderInfo) {
                $DebugPreference=$Using:DebugPreference
                $VerbosePreference=$Using:VerbosePreference
            }   
        }

        if($UseParameters)
        {
            $lines=@()
            $lines+='if($PSSenderInfo) {'
            $UseParameters|ForEach-Object {
                $lines+='$name=$Using:name'.Replace("name","$_")
            }
            $lines+='}'

            $scriptSegments+=$ExecutionContext.InvokeCommand.NewScriptBlock($lines -join ([System.Environment]::NewLine))
        }

        $scriptSegments+=$ScriptBlock

        $finalScript=""
        $scriptSegments|ForEach-Object {$finalScript+=$_.ToString()+[System.Environment]::NewLine}
        $enhancedScriptBlock=$ExecutionContext.InvokeCommand.NewScriptBlock($finalScript)

        Write-Debug "Replacing original script with injected parameters"
        Write-Debug ($enhancedScriptBlock.ToString())

        $ScriptBlock=$enhancedScriptBlock
    }


    if($Session)
    {
        Write-Debug "Targetting remote session $($session.ComputerName)"
        Write-Verbose "[$BlockName] Begin on $($session.ComputerName)"
        Invoke-Command -Session $Session -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
        Write-Host "[$BlockName] Finish on $($session.ComputerName)"
        return
    }
    if($ComputerName)
    {
        Write-Debug "Targetting remote computer $ComputerName"
        Write-Verbose "[$BlockName] Begin on $ComputerName"
        Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
        Write-Host "[$BlockName] Finish on $ComputerName"
        return
    }
    Write-Debug "Targetting local"
    Write-Verbose "[$BlockName] Begin local"
    Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
    Write-Host "[$BlockName] Finish local"
}