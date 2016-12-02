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
    [Parameter(Mandatory=$true)]
    [PSCredential]$OSUserCredential,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion
)    
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

if($Computer)
{
    . $cmdletsPaths\Helpers\Add-ModuleFromRemote.ps1
    . $cmdletsPaths\Helpers\Remove-ModuleFromRemote.ps1
}


try
{
    if($Computer)
    {
        $ishServerModuleName="xISHServer.$ISHServerVersion"
        $session=New-PSSession -ComputerName $Computer -Credential $OSUserCredential
        $remote=Add-ModuleFromRemote -Session $session -Name $ishServerModuleName
    }

    Write-Progress @scriptProgress -Status "Initializing regional settings"
    Initialize-ISHRegional
}

finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
        $session|Remove-PSSession
    }
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
