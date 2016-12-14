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

function Install-ISHToolMSXML4
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-EA97B03F-C33B-466E-A307-CA9F2B10B22D

    $fileName="MSXML.40SP3.msi"
    $filePath=Join-Path (Get-ISHServerFolderPath) $fileName
    $logFile=Join-Path $env:TEMP "$fileName.log"
    $arguments=@(
        "/package"
        $filePath
        "/qn"
        "/lv"
        $logFile
    )

    Write-Debug "Installing $fileName"
    Start-Process "msiexec" -ArgumentList $arguments -Wait
    Write-Verbose "Installed $fileName"
}
