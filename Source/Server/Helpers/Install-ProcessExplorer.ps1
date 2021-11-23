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

Param (
    [Parameter(Mandatory = $false)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$block= {
    $targetPath=Join-Path $env:ProgramFiles "ProcessExplorer"
    if(Test-Path $targetPath)
    {
        Write-Warning "Process explorer already installed at $targetPath"
        return
    }
    $downloadPath=Join-Path $env:TEMP "ProcessExplorer.zip"
    $uri = "https://download.sysinternals.com/files/ProcessExplorer.zip"
    Write-Debug "uri=$($uri.AbsoluteUri)"
    $client = New-Object System.Net.Webclient
    $client.DownloadFile($uri,$downloadPath)
    Write-Verbose "Downloaded file $($uri.AbsoluteUri) to $downloadPath"

    Write-Debug "Expanding $downloadPath to $targetPath"
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')|Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($downloadPath, $targetPath)|Out-Null
    Write-Verbose "Expanded $downloadPath to $targetPath"
    Write-Host "Process explorer available at $targetPath"
}

try
{
    $blockName="Install Process Explorer"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $block -BlockName $blockName
}
finally
{
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
