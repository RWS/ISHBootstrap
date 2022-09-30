<#
# Copyright (c) 2022 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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
    [string[]]$ModuleName,
    [Parameter(Mandatory=$false)]
    [string]$Repository,
    [Parameter(Mandatory=$false)]
    [ValidateSet("AllUsers","CurrentUser")]
    [string]$Scope="AllUsers"
)    

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$installScriptBlock={
    foreach($name in $ModuleName)
    {
        Write-Debug "Finding modules $name"
        if($Repository)
        {
            $latestModule=Find-Module -Name $name -Repository $Repository |Where-Object {$_.Name -eq $name}
        }
        else
        {
            $latestModule=Find-Module -Name $name |Where-Object {$_.Name -eq $name}
        }
        $latestModule=$latestModule|Sort-Object -Property Version -Descending|Select-Object -First 1

        if(-not $latestModule)
        {
            Write-Error "Could not find module $name"
            return
        }
        Write-Verbose "Found module $name with version $($latestModule.Version)"

        $currentModule=Get-Module -Name $name -ListAvailable
        $skipInstall=$true
        
        if(-not $currentModule)
        {
            $skipInstall=$false
        }
        else
        {
            if($currentModule.Version -lt $latestModule.Version)
            {
                $skipInstall=$false
            }
        }
        if(-not $skipInstall)
        {
            $latestModule|Install-Module -Scope $Scope -Force|Out-Null
            Write-Host "Installed module $name with version $($latestModule.Version)"
        }
        else
        {
            Write-Warning "Module $name is available with version $($currentModule.Version). Skipping..."
        }
   
    }
}

#Install the packages
try
{
    $blockName="Installing Module(s) $($ModuleName -join ',')"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $installScriptBlock -BlockName $blockName -UseParameters @("ModuleName","Repository","Scope")
}
catch
{
    Write-Error $_
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
