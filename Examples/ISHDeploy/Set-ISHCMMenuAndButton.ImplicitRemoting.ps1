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
    [string]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$true)]
    [string]$ISHVersion    
)
$ishBootStrapRootPath=Resolve-Path "$PSScriptRoot\..\.."
$ishBootStrapRootPath="C:\GitHub\ISHBootstrap"

$cmdletsPaths="$ishBootStrapRootPath\Source\Cmdlets"
$serverScriptsPaths="$ishBootStrapRootPath\Source\Server"

. $ishBootStrapRootPath\Examples\Cmdlets\Get-ISHBootstrapperContextValue.ps1
. $ishBootStrapRootPath\Examples\ISHDeploy\Cmdlets\Write-Separator.ps1
Write-Separator -Invocation $MyInvocation -Header -Name "Configure"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

if(-not $Computer)
{
    & "$serverScriptsPaths\Helpers\Test-Administrator.ps1"
}

. $cmdletsPaths\Helpers\Add-ModuleFromRemote.ps1
. $cmdletsPaths\Helpers\Remove-ModuleFromRemote.ps1

try
{
    Write-Progress @scriptProgress -Status "Setting UI Features on $DeploymentName"
    
    if($Computer)
    {
        $ishDelpoyModuleName="ISHDeploy"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Credential $Credential -Name $ishDelpoyModuleName
    }

    $hash=@{
        Label="Custom Event"
        Description="Show all custom events"
        EventTypesFilter=@("CUSTOM1","CUSTOM2")
        UserRole=@("Administrator","Author")
    }
    Set-ISHUIEventMonitorMenuBarItem -ISHDeployment $DeploymentName @hash
    Move-ISHUIEventMonitorMenuBarItem -ISHDeployment $DeploymentName -Label $hash["Label"] -First
}
finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer -Name "Configure"