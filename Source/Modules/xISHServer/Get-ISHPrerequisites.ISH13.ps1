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
. $PSScriptRoot\Get-ISHOSInfo.ps1

function Get-ISHPrerequisites
{
    param(
        [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
        [string]$FTPHost,
        [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
        [pscredential]$Credential,
        [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
        [string]$FTPFolder,
        [Parameter(Mandatory=$true,ParameterSetName="No Download")]
        [switch]$FileNames
    )
    #
    $filesToDownload=@(
        #Common for 12 and 13
        "MSXML.40SP3.msi"
        "jdk-8u60-windows-x64.exe"
        "jre-8u60-windows-x64.exe"
        "javahelp-2_0_05.zip"
        "htmlhelp.zip"
        "V6-2-M9-Windows_X64_64E.exe"
        "V6-2-M9-Windows_X64_64E.exe.iss"
        "V6-2-M9-Windows_X64_64E.exe.vcredist_x64.exe"
        "V6-2-M9-Windows_X64_64E.exe.vcredist_x86.exe"
        "ODTwithODAC121012.zip"
        "ODTwithODAC121012.rsp"

        #Specific for 13
        "NETFramework2015_4.6_MicrosoftVisualC++Redistributable_(vc_redist.x64).exe"
    )

    $osInfo=Get-ISHOSInfo
    
    if($osInfo.Server -eq "2016")
    {
    }
    else
    {
        $filesToDownload+="NETFramework2015_4.6.1.xxxxx_(NDP461-KB3102436-x86-x64-AllOS-ENU).exe"
    }

    if($osInfo.IsCore)
    {
        $filesToDownload+="vbrun60sp6.exe"
    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'From FTP' {
            Import-Module PSFTP -ErrorAction Stop
            $localPath=Get-ISHServerFolderPath
            Set-FTPConnection -Server $FTPHost -Credentials $Credential -UseBinary -KeepAlive -UsePassive | Out-Null
            $filesToDownload | ForEach-Object {
                $ftpUrl="$FTPFolder$_"

                Write-Debug "ftpUrl=$ftpUrl"
                Get-FTPItem -Path $ftpUrl -LocalPath $localPath -Overwrite | Out-Null
                Write-Verbose "Downloaded $ftpUrl"
            }
            break        
        }
        'No Download' {
            if($FileNames)
            {
                $filesToDownload
            }
            break
        }
    }
}
