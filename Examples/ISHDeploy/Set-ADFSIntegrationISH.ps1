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
    [string[]]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$false)]
    [switch]$IncludeInternalClients=$false
)        
$ishBootStrapRootPath=Resolve-Path "$PSScriptRoot\..\.."
$cmdletsPaths="$ishBootStrapRootPath\Source\Cmdlets"
$serverScriptsPaths="$ishBootStrapRootPath\Source\Server"

. $ishBootStrapRootPath\Examples\Cmdlets\Get-ISHBootstrapperContextValue.ps1
. $ishBootStrapRootPath\Examples\ISHDeploy\Cmdlets\Write-Separator.ps1
Write-Separator -Invocation $MyInvocation -Header -Name "Configure"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

if(-not $Computer)
{
    & "$serverScriptsPaths\Helpers\Test-Administrator.ps1"
}

if(-not (Get-Command Invoke-CommandWrap -ErrorAction SilentlyContinue))
{
    . $cmdletsPaths\Helpers\Invoke-CommandWrap.ps1
}  

#region adfs information
$adfsComputerName=Get-ISHBootstrapperContextValue -ValuePath "Configuration.ADFSComputerName"
#endegion

#region integraion filename
$adfsIntegrationISHFilename="$(Get-Date -Format "yyyyMMdd").ADFSIntegrationISH.zip"

#endregion

$integrationBlock= {
    Save-ISHIntegrationSTSConfigurationPackage -ISHDeployment $DeploymentName -FileName $adfsIntegrationISHFilename -ADFS

    Get-ISHPackageFolderPath -ISHDeployment $DeploymentName -UNC
}


try
{
    $blockName="Acquiring $DeploymentName integration for ADFS"
    Write-Progress @scriptProgress -Status $blockName
    $uncPath=Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $integrationBlock -BlockName $blockName -UseParameters @("DeploymentName","adfsIntegrationISHFilename")

    $sourceUncZipPath=Join-Path $uncPath $adfsIntegrationISHFilename
    $tempZipPath=Join-Path $env:TEMP $adfsIntegrationISHFilename
    Write-Debug "Downloading file from $sourceUncZipPath"
    # TODO: Expected error when client and remote machine do not belong on the same domain.
    Copy-Item -Path $sourceUncZipPath -Destination $env:TEMP -Force
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

    Write-Verbose "Configurating rellying parties on $adfsComputerName"
    Write-Progress @scriptProgress -Status "Configuring $DeploymentName integration on ADFS"
    & $scriptADFSIntegrationISHPath -Computer $adfsComputerName -Action Set -Verbose
    Write-Host "Configured rellying parties on $adfsComputerName"

}
finally
{

}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer -Name "Configure"