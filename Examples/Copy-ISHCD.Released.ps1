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

if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
$credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke
$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$ftp=Get-ISHBootstrapperContextValue -ValuePath "FTP" -DefaultValue $null
$ftpHost=$ftp.Host
$ftpCredential=Get-ISHBootstrapperContextValue -ValuePath "FTP.CredentialExpression" -Invoke
$ftpAlternateHost=$ftp.AlternativeHost
$ftpCDFolder=$ftp.ISHCDFolder
$ftpCDFileName=$ftp.ISHCDFileName

$copyBlock= {
    $targetPath="C:\IshCD\$ishVersion"
    Write-Debug "targetPath=$targetPath"
    Import-Module PSFTP -ErrorAction Stop

    if(-not (Test-Connection $ftpHost -Quiet))
    {
        Write-Warning "Using alternate host $ftpAlternateHost instead of $ftpHost"
        $ftpHost=$ftpAlternateHost
    }

    Set-FTPConnection -Server $ftpHost -Credentials $ftpCredential -UseBinary -KeepAlive -UsePassive | Out-Null
    $ftpUrl="$ftpCDFolder$ftpCDFileName"
    $localPath=$env:TEMP

    Write-Debug "ftpUrl=$ftpUrl"
    Get-FTPItem -Path $ftpUrl -LocalPath $localPath -Overwrite | Out-Null
    Write-Verbose "Downloaded $ftpUrl"

    $cdPath=Join-Path $env:TEMP $ftpCDFileName
    Write-Debug "cdPath=$cdPath"

    Write-Debug "targetPath=$targetPath"
    if(-not (Test-Path $targetPath))
    {
        New-Item $targetPath -ItemType Directory | Out-Null
    }
    Remove-Item "$targetPath\*" -Force -Recurse
    Write-Verbose "$targetPath is ready"
    
    $arguments=@("-d$targetPath","-s")
    Write-Debug "Unzipping $cdPath in $targetPath"
    Start-Process $cdPath -ArgumentList $arguments -Wait
    Write-Host "Unzipped $cdPath in $targetPath"
}

try
{

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }

    Invoke-CommandWrap -ComputerName $computerName -Credential $credential -ScriptBlock $copyBlock -BlockName "Copy and Extract ISH.$ishVersion" -UseParameters @("ishVersion","ftpHost","ftpAlternateHost","ftpCredential","ftpCDFolder","ftpCDFileName")
}
finally
{
}
