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

. $PSScriptRoot\Get-ISHServerFolderPath.ps1

function Install-ISHToolOracleODAC
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-DD65E7B5-204B-48D7-91F9-CBDCB0730B80

    $baseFileName="ODTwithODAC121012"
    $fileName="$baseFileName.zip"
    $filePath=Join-Path (Get-ISHServerFolderPath) $fileName
    $targetPath=Join-Path $env:TEMP "$baseFileName"
    if(Test-Path $targetPath)
    {
        Write-Warning "$fileName is already available in $targetPath"
    }
    else
    {
        Write-Debug "Creating $targetPath"
        New-Item $targetPath  -ItemType Directory |Out-Null
        Write-Debug "Unzipping $filePath to $targetPath"
        [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')|Out-Null
        [System.IO.Compression.ZipFile]::ExtractToDirectory($filePath, $targetPath)|Out-Null
        Write-Verbose "Unzipped $filePath"
    }

    $setupPath=Join-Path $targetPath "setup.exe"
    $rspPath=Join-Path (Get-ISHServerFolderPath) "$baseFileName.rsp"
    $arguments=@(
        "-silent"
        "-noconfig"
        "-responseFile"
        "$rspPath"
        "-nowait"
    )

    Write-Debug "Installing $setupPath using $rspPath"
    Start-Process $setupPath -ArgumentList $arguments -Wait -Verb RunAs
    Write-Verbose "Installed $setupPath"

}
