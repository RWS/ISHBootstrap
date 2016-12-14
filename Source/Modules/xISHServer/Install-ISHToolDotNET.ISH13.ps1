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

function Install-ISHToolDotNET 
{
    $osInfo=Get-ISHOSInfo
    if($osInfo.Version -eq "2016")
    {
        Write-Verbose "Assuming .NET 4.6.2 is installed on $($osInfo.Caption)"
    }
    else
    {
        $fileName="NETFramework2015_4.6.1.xxxxx_(NDP461-KB3102436-x86-x64-AllOS-ENU).exe"
        $filePath=Join-Path (Get-ISHServerFolderPath) $fileName
        $logFile=Join-Path $env:TEMP "$FileName.htm"
        $arguments=@(
            "/q"
            "/norestart"
            "/log"
            "$logFile"
        )

        Write-Debug "Installing $filePath"
        Start-Process $filePath -ArgumentList $arguments -Wait -Verb RunAs
        Write-Verbose "Installed $fileName"
        Write-Warning "You must restart the server before you proceed."
    }
}
