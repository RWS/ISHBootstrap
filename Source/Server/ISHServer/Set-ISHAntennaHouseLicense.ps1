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
    [string]$Computer=$null,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13","14","15")]
    [string]$ISHServerVersion,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [string]$FTPHost,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [pscredential]$FTPCredential,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [ValidatePattern(".*AHFormatter\.lic")]
    [string]$FTPPath,
    [Parameter(Mandatory=$true,ParameterSetName="From AWS S3")]
    [string]$BucketName,
    [Parameter(Mandatory=$true,ParameterSetName="From AWS S3")]
    [ValidatePattern(".*AHFormatter\.lic")]
    [string]$Key,
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [string]$AccessKey,
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [string]$ProfileName,
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [string]$ProfileLocation,
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [string]$Region,
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [string]$SecretKey,
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [string]$SessionToken,
    [Parameter(Mandatory=$true,ParameterSetName="From Azure FileStorage")]
    [string]$ShareName,
    [Parameter(Mandatory=$true,ParameterSetName="From Azure FileStorage")]
    [ValidatePattern(".*AHFormatter\.lic")]
    [string]$Path,
    [Parameter(Mandatory=$true,ParameterSetName="From Azure BlobStorage")]
    [string]$ContainerName,
    [Parameter(Mandatory=$true,ParameterSetName="From Azure BlobStorage")]
    [ValidatePattern(".*AHFormatter\.lic")]
    [string]$BlobName,
    [Parameter(Mandatory=$false,ParameterSetName="From Azure FileStorage")]
    [Parameter(Mandatory=$false,ParameterSetName="From Azure BlobStorage")]
    [string]$StorageAccountName,
    [Parameter(Mandatory=$false,ParameterSetName="From Azure FileStorage")]
    [parameter(ParameterSetName="From Azure BlobStorage")]
    [string]$StorageAccountKey,
    [Parameter(Mandatory=$true,ParameterSetName="From File")]
    [string]$FilePath
)    
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

if($Computer)
{
    . $cmdletsPaths\Helpers\Add-ModuleFromRemote.ps1
    . $cmdletsPaths\Helpers\Remove-ModuleFromRemote.ps1
}

try
{
    if($Computer)
    {
        $ishServerModuleName="ISHServer.$ISHServerVersion"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Credential $Credential -Name $ishServerModuleName
    }

    Write-Progress @scriptProgress -Status "Copying Antenna House license"
    switch ($PSCmdlet.ParameterSetName)
    {
        'From FTP' {
            Set-ISHToolAntennaHouseLicense -FTPHost $FTPHost -Credential $FTPCredential -FTPPath $FTPPath
            break        
        }
        'From AWS S3' {
            Set-ISHToolAntennaHouseLicense -BucketName $BucketName -Key $Key -AccessKey $AccessKey -ProfileName $ProfileName -ProfileLocation $ProfileLocation -Region $Region -SecretKey $SecretKey -SessionToken $SessionToken
            break        
        }
        'From Azure FileStorage' {
            Set-ISHToolAntennaHouseLicense -ShareName $ShareName -Path $Path -Expand -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
            break        
        }
        'From Azure BlobStorage' {
            Set-ISHToolAntennaHouseLicense -ContainerName $ContainerName -BlobName $BlobName -Expand -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
            break        
        }
        'From File' {
            $license=Get-Content -Path $FilePath
            Set-ISHToolAntennaHouseLicense -Content $license
            break
        }
    }
}

finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
