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
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceLocation,
    [Parameter(Mandatory=$false)]
    [string]$PublishLocation=$null,
    [Parameter(Mandatory=$false)]
    [ValidateSet("Trusted","Untrusted")]
    [string]$InstallationPolicy="Trusted"
)        

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$registerPSRepositoryBlock = {
    Write-Debug "Name=$Name"
    Write-Debug "SourceLocation=$SourceLocation"
    Write-Debug "PublishLocation=$PublishLocation"
    Write-Debug "InstallationPolicy=$InstallationPolicy"
    
    Write-Debug "Unregistering repository $Name"
    Unregister-PSRepository -Name $Name -ErrorAction SilentlyContinue | Out-Null
    Write-Debug "Registering repository $Name"
    if($PublishLocation)
    {
        Register-PSRepository -Name $Name -SourceLocation $SourceLocation -PublishLocation  $PublishLocation -InstallationPolicy $InstallationPolicy | Out-Null
    }
    else
    {
        Register-PSRepository -Name $Name -SourceLocation $SourceLocation -InstallationPolicy $InstallationPolicy | Out-Null
    }
}


try
{
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $registerPSRepositoryBlock -BlockName "Register Repository $Name" -UseParameters @("Name","SourceLocation","PublishLocation","InstallationPolicy")
}
catch
{
    Write-Error $_
}

Write-Separator -Invocation $MyInvocation -Footer
