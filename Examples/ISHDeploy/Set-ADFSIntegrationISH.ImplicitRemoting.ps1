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
    [string[]]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$true)]
    [string]$ISHVersion,
    [Parameter(Mandatory=$false)]
    [switch]$IncludeInternalClients=$false
)        
$ishBootStrapRootPath=Resolve-Path "$PSScriptRoot\..\.."
$cmdletsPaths="$ishBootStrapRootPath\Source\Cmdlets"
$serverScriptsPaths="$ishBootStrapRootPath\Source\Server"

if(-not $Computer)
{
    & "$serverScriptsPaths\Helpers\Test-Administrator.ps1"
}

. $ishBootStrapRootPath\Examples\Cmdlets\Get-ISHBootstrapperContextValue.ps1
. $ishBootStrapRootPath\Examples\ISHDeploy\Cmdlets\Write-Separator.ps1
Write-Separator -Invocation $MyInvocation -Header -Name "Configure"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. $cmdletsPaths\Helpers\Add-ModuleFromRemote.ps1
. $cmdletsPaths\Helpers\Remove-ModuleFromRemote.ps1

try
{
    #region adfs information
    $adfsComputerName=Get-ISHBootstrapperContextValue -ValuePath "Configuration.ADFSComputerName"
    #endegion

    #region integraion filename
    $adfsIntegrationISHFilename="$(Get-Date -Format "yyyyMMdd").ADFSIntegrationISH.zip"

    #endregion

    Write-Progress @scriptProgress -Status "Acquiring $DeploymentName integration for ADFS"

    if($Computer)
    {
        $ishDelpoyModuleName="ISHDeploy"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Credential $Credential -Name $ishDelpoyModuleName
    }
    $remoteADFS=Add-ModuleFromRemote -ComputerName $adfsComputerName -Name ADFS

    #region Retrieve integration package
    Save-ISHIntegrationSTSConfigurationPackage -ISHDeployment $DeploymentName -FileName $adfsIntegrationISHFilename -ADFS

    $absoluteOnRemotePath=Get-ISHPackageFolderPath -ISHDeployment $DeploymentName

    $sourceAbsoluteOnRemoteZipPath=Join-Path $absoluteOnRemotePath $adfsIntegrationISHFilename
    $tempZipPath=Join-Path $env:TEMP $adfsIntegrationISHFilename
    Write-Debug "Downloading file from $sourceUncZipPath"
    if($Computer)
    {
        if($PSVersionTable.PSVersion.Major -ge 5)
        {
            Copy-Item -Path $sourceAbsoluteOnRemoteZipPath -Destination $env:TEMP -Force -FromSession $remote.Session
        }
        else
        {
            throw "Not supported path. Required PowerShell v5"
        }
    }
    else
    {
        Copy-Item -Path $sourceAbsoluteOnRemoteZipPath -Destination $env:TEMP -Force
    }
    if(-not (Test-Path $tempZipPath))
    {
        throw "Cannot find file $tempZipPath"
    }
    Write-Verbose "Downloaded file to $tempZipPath"

    $expandPath=Join-Path $env:TEMP ($adfsIntegrationISHFilename.Replace(".zip",""))
    if(Test-Path ($expandPath))
    {
        Write-Warning "$expandPath exists. Removing"
        Remove-Item $expandPath -Force -Recurse | Out-Null
    }

    New-Item -Path $expandPath -ItemType Directory|Out-Null

    Write-Debug "Expanding $tempZipPath to $expandPath"
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')|Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZipPath, $expandPath)|Out-Null
    Write-Verbose "Expanded $tempZipPath to $expandPath"

    $scriptADFSIntegrationISHPath=Join-Path $expandPath "Invoke-ADFSIntegrationISH.ps1"
    #endregion

    #region Execute integration script
    Write-Verbose "Configurating rellying parties on $adfsComputerName"
    Write-Progress @scriptProgress -Status "Configuring $DeploymentName integration on ADFS"
    & $scriptADFSIntegrationISHPath -Computer $adfsComputerName -Action Set -Verbose
    Write-Host "Configured rellying parties on $adfsComputerName"
    #endregion

}
finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
    Remove-ModuleFromRemote -Remote $remoteADFS
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer -Name "Configure"