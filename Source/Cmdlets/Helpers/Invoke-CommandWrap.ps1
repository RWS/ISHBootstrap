<#
# Copyright (c) 2014 All Rights Reserved by the SDL Group.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#>

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
    .PARAMETER  ComputerName
        Target computer
    .PARAMETER  Credential
        Target Credential
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
        [Parameter(Mandatory=$true,ParameterSetName="Local")]
        [Parameter(Mandatory=$true,ParameterSetName="Computer")]
        [Parameter(Mandatory=$true,ParameterSetName="Session")]
        $ScriptBlock,
        [Parameter(Mandatory=$true,ParameterSetName="Local")]
        [Parameter(Mandatory=$true,ParameterSetName="Computer")]
        [Parameter(Mandatory=$true,ParameterSetName="Session")]
        $BlockName,
        [Parameter(Mandatory=$false,ParameterSetName="Local")]
        [Parameter(Mandatory=$false,ParameterSetName="Computer")]
        [Parameter(Mandatory=$false,ParameterSetName="Session")]
        $ArgumentList=$null,
        [Parameter(Mandatory=$true,ParameterSetName="Computer")]
        [AllowNull()]
        $ComputerName=$null,
        [Parameter(Mandatory=$false,ParameterSetName="Computer")]
        [pscredential]$Credential=$null,
        [Parameter(Mandatory=$true,ParameterSetName="Session")]
        [AllowNull()]
        $Session=$null,
        [Parameter(Mandatory=$false,ParameterSetName="Local")]
        [Parameter(Mandatory=$false,ParameterSetName="Computer")]
        [Parameter(Mandatory=$false,ParameterSetName="Session")]
        [string[]]$UseParameters=$null
    ) 
    
    . $PSScriptRoot\Get-ProgressHash.ps1
    $activity="Invoke script block"
    switch ($PSCmdlet.ParameterSetName)
    {
        'Local' {$cmdLetProgress=Get-ProgressHash -Activity $activity}
        'Computer' {$cmdLetProgress=Get-ProgressHash -Activity $activity -ComputerName $ComputerName}
        'Session' {$cmdLetProgress=Get-ProgressHash -Activity $activity -Session $Session}
    }
    
    if($Session -or $ComputerName)
    {
        $scriptSegments=@()
        $normalizedScriptBlock=$ScriptBlock
        if($ScriptBlock.Ast.ParamBlock)
        {
            $scriptSegments +=$ScriptBlock.Ast.ParamBlock
            $normalizedScriptBlock=$ExecutionContext.InvokeCommand.NewScriptBlock($ScriptBlock.ToString().Replace($ScriptBlock.Ast.ParamBlock.ToString(),""))
        }
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
        $scriptSegments+=$normalizedScriptBlock

        $finalScript=""
        $scriptSegments|ForEach-Object {$finalScript+=$_.ToString()+[System.Environment]::NewLine}
        $enhancedScriptBlock=$ExecutionContext.InvokeCommand.NewScriptBlock($finalScript)

        Write-Debug "Replacing original script with injected parameters"
        Write-Debug ($enhancedScriptBlock.ToString())

        $ScriptBlock=$enhancedScriptBlock
    }

    Write-Progress @cmdLetProgress -Status $BlockName
    switch ($PSCmdlet.ParameterSetName)
    {
        'Session' {
            Write-Debug "Targetting remote session $($session.ComputerName)"
            Write-Verbose "[$BlockName] Begin on $($session.ComputerName)"
            Invoke-Command -Session $Session -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
            Write-Host "[$BlockName] Finish on $($session.ComputerName)"        
        }
        'Computer' {
            Write-Debug "Targetting remote computer $ComputerName"
            Write-Verbose "[$BlockName] Begin on $ComputerName"
            if($Credential)
            {
                Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
            }
            else
            {
                Invoke-Command -ComputerName $ComputerName -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
            }
            Write-Host "[$BlockName] Finish on $ComputerName"
        }
        'Local' {
            Write-Debug "Targetting local"
            Write-Verbose "[$BlockName] Begin local"
            Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
            Write-Host "[$BlockName] Finish local"
        }
    }
    Write-Progress @cmdLetProgress -Completed
}
