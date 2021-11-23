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

param(
    [Parameter(Mandatory=$false)]
    [switch]$UseISHDeployImplicit=$false,
    [Parameter(Mandatory=$true,ParameterSetName="Undo")]
    [switch]$Undo,
    [Parameter(Mandatory=$true,ParameterSetName="Status")]
    [switch]$Status,
    [Parameter(Mandatory=$true,ParameterSetName="Configure")]
    [switch]$Configure
)
if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$serverScriptsPaths="$sourcePath\Server"


try
{

    . "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
    $computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
    $credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke

    if(-not $computerName)
    {
        & "$serverScriptsPaths\Helpers\Test-Administrator.ps1"
    }

    . "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

    $ishDeployments=Get-ISHBootstrapperContextValue -ValuePath "ISHDeployment"
    $ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"

    foreach($ishDeployment in $ishDeployments)
    {
        $deploymentName=$ishDeployment.Name
        $scriptsToExecute=@()
        switch ($PSCmdlet.ParameterSetName)
        {
            'Undo' {
                $scriptFileName="Undo-ISHDeployment.ps1"
                $folderPath=Join-Path $PSScriptRoot "ISHDeploy"
                $scriptPath=Join-Path $folderPath $scriptFileName
                $scriptsToExecute+=$scriptPath
            }
            'Configure' {
                $ishDeployment.Scripts | ForEach-Object {
                    $scriptFileName=$_
                    $scriptPath=Join-Path $PSScriptRoot $scriptFileName
                    if(Test-Path $scriptPath)
                    {
                        $scriptsToExecute+=$scriptPath
                    }
                    else
                    {
                        $folderPath=Get-ISHBootstrapperContextValue -ValuePath "FolderPath"
                        $scriptPath=Join-Path $folderPath $scriptFileName
                        if(Test-Path $scriptPath)
                        {
                            $scriptsToExecute+=$scriptPath
                        }
                        else
                        {
                            Write-Warning "$scriptFileName not found in $PSScriptRoot or in $folderPath. Skipping."
                        }
                    }
                }            
            }
            'Status' {
                $scriptFileName="Get-Status.ps1"
                $folderPath=Join-Path $PSScriptRoot "ISHDeploy"
                $scriptPath=Join-Path $folderPath $scriptFileName
                $scriptsToExecute+=$scriptPath
            }
        }
        $scriptsToExecute | ForEach-Object {
            $scriptPath=$_
            if($UseISHDeployImplicit)
            {
                $scriptPath=$scriptPath.Replace(".ps1",".ImplicitRemoting.ps1")
            }
            Write-Debug "scriptPath=$scriptPath"
            $scriptPath=Resolve-Path $scriptPath

            if($UseISHDeployImplicit)
            {
                & $scriptPath -Computer $computerName -Credential $credential -DeploymentName $deploymentName -ISHVersion $ishVersion
            }
            else
            {
                & $scriptPath -Computer $computerName -Credential $credential -DeploymentName $deploymentName
            }
            Write-Verbose "Executing $scriptPath -Computer $computerName -DeploymentName $deploymentName"
        }
    }

}
finally
{
}
