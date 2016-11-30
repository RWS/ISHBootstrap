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
    [string]$DeploymentName
)
$ishBootStrapRootPath=Resolve-Path "$PSScriptRoot\..\.."
$cmdletsPaths="$ishBootStrapRootPath\Source\Cmdlets"
$scriptsPaths="$ishBootStrapRootPath\Source\Scripts"

. $ishBootStrapRootPath\Examples\Cmdlets\Get-ISHBootstrapperContextValue.ps1
. $ishBootStrapRootPath\Examples\ISHDeploy\Cmdlets\Write-Separator.ps1
Write-Separator -Invocation $MyInvocation -Header -Name "Configure"

if(-not $Computer)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

if(-not (Get-Command Invoke-CommandWrap -ErrorAction SilentlyContinue))
{
    . $cmdletsPaths\Helpers\Invoke-CommandWrap.ps1
}        

$setUIFeaturesScirptBlock= {
    # Create a new tab for CUSTOM event types
    $hash=@{
        Label="Custom Event"
        Description="Show all custom events"
        EventTypesFilter=@("CUSTOM1","CUSTOM2")
        UserRole=@("Administrator","Author")
    }
    Set-ISHUIEventMonitorTab -ISHDeployment $DeploymentName @hash
    Move-ISHUIEventMonitorTab -ISHDeployment $DeploymentName -Label $hash["Label"] -First
    Write-Host "Event monitor tab created"
}


#Install the packages
try
{
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $setUIFeaturesScirptBlock -BlockName "Set UI Features on $DeploymentName" -UseParameters @("DeploymentName")
}
finally
{

}

Write-Separator -Invocation $MyInvocation -Footer -Name "Configure"
