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

param (
    [Parameter(Mandatory=$false)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [string]$FTPHost,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [pscredential]$FTPCredential,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [ValidatePattern(".+\.[0-9]+\.0\.[0-9]+\.[0-9]+.*\.exe")]
    [string]$FTPPath,
    [Parameter(Mandatory=$true,ParameterSetName="From AWS S3")]
    [string]$BucketName,
    [Parameter(Mandatory=$true,ParameterSetName="From AWS S3")]
    [ValidatePattern(".+\.[0-9]+\.0\.[0-9]+\.[0-9]+.*\.exe")]
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
    [Parameter(Mandatory=$true,ParameterSetName="From UNC")]
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

    Write-Progress @scriptProgress -Status "Copying and expanding CD"
    switch ($PSCmdlet.ParameterSetName)
    {
        'From FTP' {
            Get-ISHCD -FTPHost $FTPHost -Credential $FTPCredential -FTPPath $FTPPath -Expand
            break        
        }
        'From AWS S3' {
            Get-ISHCD -BucketName $BucketName -Key $Key -Expand -AccessKey $AccessKey -ProfileName $ProfileName -ProfileLocation $ProfileLocation -Region $Region -SecretKey $SecretKey -SessionToken $SessionToken
            break        
        }
        'From File' {
            if($Computer)
            {
                if($PSVersionTable.PSVersion.Major -ge 5)
                {
                    $targetPath=Get-ISHServerFolderPath
                    Copy-Item -Path $FilePath -Destination $targetPath -Force -ToSession $remote.Session
                }
                else
                {
                    # Need a unc path to copy to remote server from PowerShell v.4
                    $targetPath=Get-ISHServerFolderPath -UNC
                    # Use the unc path
                    Copy-Item -Path $FilePath -Destination $targetPath -Force
                }
            }    
            else
            {
                $targetPath=Get-ISHServerFolderPath
                Copy-Item -Path $FilePath -Destination $targetPath -Force
            }
            Write-Verbose "Uploaded CD to $targetPath"

            Write-Debug "Expanding CD"
            $fileName=Split-Path -Path $FilePath -Leaf
            Write-Debug "fileName=$fileName"
            Expand-ISHCD -Filename $fileName
            Write-Verbose "Expanded CD"
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
