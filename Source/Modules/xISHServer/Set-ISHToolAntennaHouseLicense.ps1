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

function Set-ISHToolAntennaHouseLicense
{
    param(
        [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
        [string]$FTPHost,
        [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
        [pscredential]$Credential,
        [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
        [ValidatePattern(".*AHFormatter\.lic")]
        [string]$FTPPath,
        [Parameter(Mandatory=$true,ParameterSetName="Content")]
        $Content
    )

    $antennaHouseLicenseFileName="AHFormatter.lic"
    $antennaHouseFolderPath=Join-Path $env:ProgramFiles "Antenna House\AHFormatterV62\"
    $antennaHouseLicensePath=Join-Path $antennaHouseFolderPath $antennaHouseLicenseFileName
    if(Test-Path $antennaHouseLicensePath)
    {
        $stamp=Get-Date -Format "yyyyMMdd"
        $newFileName="$stamp.ISHServer.$antennaHouseLicenseFileName.bak"
        $backupPath=Join-Path (Get-ISHServerFolderPath) $newFileName
        if(Test-Path (Join-Path $antennaHouseFolderPath $newFileName))
        {
            $stamp=Get-Date -Format "yyyyMMdd-hhmmss"
            $newFileName="$stamp.ISHServer.$antennaHouseLicenseFileName.bak"
            $backupPath=Join-Path (Get-ISHServerFolderPath) $newFileName
        }
        Copy-Item -Path $antennaHouseLicensePath -Destination $backupPath
        Write-Warning "License $antennaHouseLicensePath already exists. Backup available as $newFileName"
    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'From FTP' {
            Import-Module PSFTP -ErrorAction Stop
            Set-FTPConnection -Server $FTPHost -Credentials $Credential -UseBinary -KeepAlive -UsePassive | Out-Null
            Write-Debug "FTPPath=$FTPPath"
            Get-FTPItem -Path $FTPPath -LocalPath $antennaHouseFolderPath -Overwrite | Out-Null
            Write-Verbose "Downloaded $ftpUrl"
            break        
        }
        'Content' {
            Write-Debug "Writing License $antennaHouseLicensePath"
            if($PSVersionTable.PSVersion.Major -ge 5)
            {
                Set-Content -Path $antennaHouseLicensePath -Value $Content -NoNewline -Force -Encoding Default
            }
            else
            {
                [System.IO.File]::WriteAllText($antennaHouseLicensePath,$Content,[System.Text.Encoding]::Default)
            }
            Write-Verbose "License copied $antennaHouseLicensePath"
        }
    }
}
