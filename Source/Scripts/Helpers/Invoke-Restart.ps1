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

param (
    [Parameter(Mandatory=$true)]
    [string[]]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null
) 
    
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

Write-Verbose "Restarting $Computer"
Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock {Restart-Computer -Force} -BlockName "Restarting" -ErrorAction SilentlyContinue

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
<#
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
#>
    try
    {
        Write-Debug "Invoking powershell remote for $Computer"
        Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock $testBlock -ErrorVariable $errorVariable -ErrorAction Stop
    }
    catch
    {
        Write-Warning "Failed powershell remote for $Computer"
        $areAlive=$false
    }

}while(-not $areAlive)

Write-Host "$Computer is back online"
Write-Separator -Invocation $MyInvocation -Footer
