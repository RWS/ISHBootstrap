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
. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextSource.ps1"
. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
$credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke
if(-not $computerName)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
$ishServerVersion=($ishVersion -split "\.")[0]

$unc=Get-ISHBootstrapperContextSource -UNC
$ftp=Get-ISHBootstrapperContextSource -FTP
$awss3=Get-ISHBootstrapperContextSource -AWSS3

if($unc)
{
    $internalCDFolder=$unc.ISHCDFolder
    $cdObject=((Get-ChildItem $internalCDFolder |Where-Object{Test-Path $_.FullName -PathType Leaf}| Sort-Object FullName -Descending)[0])
    & $scriptsPaths\ISHServer\Copy-ISHCD.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -FilePath $cdObject.FullName 
}
if($ftp)
{
    $ftpPath="$($ftp.ISHCDFolder)$($ftp.ISHCDFileName)"
    & $scriptsPaths\ISHServer\Copy-ISHCD.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -FTPHost $ftp.Host -FTPCredential $ftp.Credential -FTPPath $ftpPath
}
if($awss3)
{
    $key="$($awss3.ISHCDFolderKey)$($awss3.ISHCDFileName)"
    & $scriptsPaths\ISHServer\Copy-ISHCD.ps1 -Computer $computerName -Credential $credential -ISHServerVersion $ishServerVersion -BucketName $awss3.BucketName -Key $key -AccessKey $awss3.AccessKey -SecretKey $awss3.SecretKey
}

