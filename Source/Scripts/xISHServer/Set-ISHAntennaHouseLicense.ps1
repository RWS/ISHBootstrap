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
    [string]$FTPPath,
    [Parameter(Mandatory=$true,ParameterSetName="From File")]
    [string]$FilePath
)    
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

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
        $ishServerModuleName="xISHServer.$ISHServerVersion"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Credential $Credential -Name $ishServerModuleName
    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'From FTP' {
            Set-ISHToolAntennaHouseLicense -FTPHost $FTPHost -Credential $FTPCredential -FTPPath $FTPPath
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

Write-Separator -Invocation $MyInvocation -Footer
