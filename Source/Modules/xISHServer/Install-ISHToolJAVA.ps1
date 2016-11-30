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

function Install-ISHToolJAVA 
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-D385255A-3644-485A-9B76-2D8695C0F000
    $fileNames=@("jre-8u60-windows-x64.exe","jdk-8u60-windows-x64.exe")
    $arguments=@(
        "/s"
    )

    foreach($fileName in $fileNames)
    {
        $filePath=Join-Path (Get-ISHServerFolderPath) $fileName

        Write-Debug "Installing $filePath"
        Start-Process $filePath -ArgumentList $arguments -Wait -Verb RunAs
        Write-Verbose "Installed $fileName"
    }

    [Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Java\jre1.8.0_60", "Machine")
}
