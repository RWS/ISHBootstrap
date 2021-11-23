<#
# Copyright (c) 2021 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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
    [Parameter(Mandatory=$false)]
    [switch]$ReInstall=$false
)        

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$packageManagementScriptBlock={
    if($PSVersionTable.PSVersion.Major -ge 5)
    {
        Write-Verbose "PowerShell v5 found. Skipping"
        return
    }

    if(Get-Command Install-Package -ErrorAction SilentlyContinue)
    {
        if(-not $ReInstall)
        {
            Write-Verbose "PackageManagement module is installed"
            return
        }
        else
        {
            Write-Verbose "PackageManagement module will be reinstalled"
        }
    }
    $msiName="PackageManagement_x64.msi"
    $downloadUrl="https://download.microsoft.com/download/C/4/1/C41378D4-7F41-4BBE-9D0D-0E4F98585C61/PackageManagement_x64.msi"
    $msiPath="$env:USERPROFILE\Downloads\$msiName"

    Write-Debug "Downloading $downloadUrl to $msiPath"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($downloadUrl, $msiPath)
    Write-Verbose "Downloaded $downloadUrl"

    $logFile=Join-Path $env:TEMP "$msiName.log"
    Write-Debug "Installing $msiPath"
    Start-Process $msiPath -ArgumentList @("/qn","/lv",$logFile) -Wait
    Write-Verbose "Installed $msiPath"
}

#Install the packages
try
{
    $blockName="Installing Package Management"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $packageManagementScriptBlock -BlockName $blockName -UseParameters @("ReInstall")
}
catch
{
    Write-Error $_
}
Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
