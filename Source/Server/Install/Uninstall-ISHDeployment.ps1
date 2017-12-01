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
    [string]$ISHVersion,
    [Parameter(Mandatory=$false)]
    $Name="InfoShare"
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$findCDPath={
    $major=($ISHVersion -split '\.')[0]
    $revision=($ISHVersion -split '\.')[2]
    $expandedCDs=Get-ISHCD -ListAvailable|Where-Object -Property IsExpanded -EQ $true
    $matchingVersionCDs=$expandedCDs|Where-Object -Property Major -EQ $major | Where-Object -Property Revision -EQ $revision
    $availableCD=$matchingVersionCDs|Sort-Object -Descending -Property Build
    if(-not $availableCD)
    {
        throw "No matching CD found"
        return
    }
    if($availableCD -is [array])
    {
        $availableCD=$availableCD[0]
        Write-Warning "Found more than one cd. Using $($availableCD.Name)"
    }
    $availableCD.ExpandedPath
}

$scriptBlock={
    & taskkill /im DllHost.exe /f
    $installToolPath=Join-Path $cdPath "__InstallTool\InstallTool.exe"
    $installToolArgs=@("-Uninstall",
        "-project",$Name
        )

    & $installToolPath $installToolArgs
}

try
{
    $blockName="Finding CD for $ISHVersion"
    Write-Progress @scriptProgress -Status $blockName
    $cdPath=Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $findCDPath -BlockName $blockName -UseParameters @("ISHVersion")

    $blockName="Uninstalling $Name"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $scriptBlock -BlockName $blockName -UseParameters @("cdPath","Name")
}
catch
{
    Write-Error $_
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer