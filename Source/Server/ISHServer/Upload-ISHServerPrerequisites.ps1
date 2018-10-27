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
    [string]$PrerequisitesSourcePath,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13","14")]
    [string]$ISHServerVersion
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
    
    $filesToCopy=Get-ISHPrerequisites -FileNames

    Write-Debug "filesToCopy=$filesToCopy"
    $filePathToCopy=$filesToCopy|ForEach-Object{Join-Path $PrerequisitesSourcePath $_}
    
    if($Computer)
    {
        if($PSVersionTable.PSVersion.Major -ge 5)
        {
            $targetPath=Get-ISHServerFolderPath
        }
        else
        {
            # Need a unc path to copy to remote server from PowerShell v.4
            $targetPath=Get-ISHServerFolderPath -UNC
        }
    }    
    else
    {
        $targetPath=Get-ISHServerFolderPath
    }

    Write-Debug "targetPath=$targetPath"

    if($Computer)
    {
        Write-Progress @scriptProgress -Status "Copying files to $Computer"

        if($PSVersionTable.PSVersion.Major -ge 5)
        {
            Copy-Item -Path $filePathToCopy -Destination $targetPath -Force -ToSession $remote.Session
        }
        else
        {
            # Use the unc path
            Copy-Item -Path $filePathToCopy -Destination $targetPath -Force
        }
    }    
    else
    {
        Write-Progress @scriptProgress -Status "Copying files"

        Copy-Item -Path $filePathToCopy -Destination $targetPath -Force
    }

    Write-Verbose "Uploaded files to $targetPath"
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
