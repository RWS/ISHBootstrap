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
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

Write-Verbose "Restarting $Computer"
$blockName="Restarting $Computer"
Write-Progress @scriptProgress -Status $blockName
Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock {Restart-Computer -Force} -BlockName $blockName -ErrorAction SilentlyContinue

Write-Host "Initiated $Computer restart"

$testBlock = {
    Write-Host "$($env:COMPUTERNAME) is alive"
}

    
do {
    $sleepSeconds=5
    for($i=0;$i -lt $sleepSeconds;$i++)
    {
        Write-Progress @scriptProgress -SecondsRemaining ($sleepSeconds-$i) -Status "Waiting before next attempt to connect with $Computer"
        Start-Sleep -Seconds 1
    }
    
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
        Write-Progress @scriptProgress -Status "Attempting PowerShell remoting to $Computer"
        Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock $testBlock -ErrorVariable $errorVariable -ErrorAction Stop
    }
    catch
    {
        Write-Warning "Failed powershell remote for $Computer"
        $areAlive=$false
    }

}while(-not $areAlive)

Write-Host "$Computer is back online"
Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
