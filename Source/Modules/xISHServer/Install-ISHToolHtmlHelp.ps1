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

function Install-ISHToolHtmlHelp 
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-7FADBDFC-919D-435F-8E0F-C54A4922100A
    #The original htmlhelp.exe cannot be automated. Extract and create a new zip file.
    $fileName="htmlhelp.zip"
    $filePath=Join-Path (Get-ISHServerFolderPath) $fileName
    $targetPath=Join-Path ${env:ProgramFiles(x86)} "HTML Help Workshop"
    if(Test-Path $targetPath)
    {
        Write-Warning "$fileName is already installed in $targetPath"
        return
    }
    Write-Debug "Creating $targetPath"
    New-Item $targetPath  -ItemType Directory |Out-Null
    Write-Debug "Unzipping $filePath to $targetPath"
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')|Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($filePath, $targetPath)|Out-Null
    Write-Verbose "Installed $filePath"
}
