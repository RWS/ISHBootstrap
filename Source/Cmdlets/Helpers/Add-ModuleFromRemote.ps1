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
        . $PSScriptRoot\Get-ProgressHash.ps1
        $activity="Import module"
        switch ($PSCmdlet.ParameterSetName)
        {
            'Local' {$cmdLetProgress=Get-ProgressHash -Activity $activity}
            'Computer' {$cmdLetProgress=Get-ProgressHash -Activity $activity -ComputerName $ComputerName}
            'Session' {$cmdLetProgress=Get-ProgressHash -Activity $activity -Session $Session}
        }
        Write-Progress @cmdLetProgress -Status "$($Name -join ',')"

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
        Write-Progress @cmdLetProgress -Completed
        New-Object PSObject -Property $undoHash
    }
}
