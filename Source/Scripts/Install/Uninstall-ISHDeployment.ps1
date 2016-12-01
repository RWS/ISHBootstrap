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
    [string]$Computer=$null,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    $CDPath,
    [Parameter(Mandatory=$false)]
    $Name="InfoShare"
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$scriptBlock={
    & taskkill /im DllHost.exe /f
    $installToolPath=Join-Path $CDPath "__InstallTool\InstallTool.exe"
    $installToolArgs=@("-Uninstall",
        "-project",$Name
        )
    & $installToolPath $installToolArgs
}

try
{
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $scriptBlock -BlockName "Uninstall $Name" -UseParameters @("CDPath","Name")
}
catch
{
    Write-Error $_
}

Write-Separator -Invocation $MyInvocation -Footer