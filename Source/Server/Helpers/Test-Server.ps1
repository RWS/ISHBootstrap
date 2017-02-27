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
    [string]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$false)]
    [int]$Attempts=10,
    [Parameter(Mandatory=$false)]
    [int]$PauseSeconds=1
) 
    
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$testBlock = {
    Write-Verbose "$($env:COMPUTERNAME) is alive"
}

    
$isAlive=$false
for($i=0;$i -lt $Attempts;$i++)
{
    Write-Progress @scriptProgress -Status "Waiting $Computer"
    Start-Sleep -Seconds $PauseSeconds
    
    Write-Debug "Attempting $($i+1) connection with $Computer"
    try
    {
        Write-Debug "Invoking powershell remote for $Computer"
        if($Credential)
        {
            Invoke-Command -ComputerName $Computer -Credential $Credential -ScriptBlock $testBlock -ErrorVariable $errorVariable -ErrorAction Stop
        }
        else
        {
            Invoke-Command -ComputerName $Computer -ScriptBlock $testBlock -ErrorVariable $errorVariable -ErrorAction Stop
        }
        $isAlive=$true
        break
    }
    catch
    {
        Write-Warning "Attempt $($i+1)/$Attempts failed for $Computer"
    }
}

if(-not $isAlive)
{
    Write-Warning "$Computer is not alive after $Attempts attempts"
}
$isAlive
Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
