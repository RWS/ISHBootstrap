<#
# Copyright (c) 2022 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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
$serverScriptsPaths="$sourcePath\Server"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
$credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke
$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"


$getDeploymentsBlock= {
    $ishDeployModuleName="ISHDeploy"
    if(Get-Module $ishDeployModuleName -ListAvailable)
    {
        Get-ISHDeployment |Select-Object -ExpandProperty Name
    }
    else
    {
        Write-Warning "$ishDeployModuleName is not available. Falling back into working with the files created by Install-ISH.ps1 ($rootPath\inputparameters-*.xml)"
        $inputParameterFiles=Get-ChildItem $rootPath -Filter "inputparameters-*.xml"

        $inputParameterFiles | ForEach-Object {
            $fileName=$_.Name
            if ($fileName -match "inputparameters-(?<name>.*)\.xml")
            {
                $Matches["name"]
            }
            else
            {
                Write-Warning "Not a valid input parameter file $fileName"
            }
        }
    }
}

try
{

    if(-not $computerName)
    {
        & "$serverScriptsPaths\Helpers\Test-Administrator.ps1"
    }

    $ishDeploymentNames=Invoke-CommandWrap -ComputerName $computerName -Credential $credential -ScriptBlock $getDeploymentsBlock -BlockName "Get ISHDeployment Names" -UseParameters @("ishVersion")
    if($ishDeploymentNames)
    {
        foreach($ishDeploymentName in $ishDeploymentNames)
        {
            Write-Debug "Uninstalling $ishDeploymentName from $cdPath"
            & $serverScriptsPaths\Install\Uninstall-ISHDeployment.ps1 -Computer $computerName -Credential $credential -ISHVersion $ishVersion -Name $ishDeploymentName
            Write-Verbose "Uninstalled $ishDeploymentName from $cdPath"
        }
    }
    else
    {
        Write-Warning "No deployments found to uninstall"
    }
}
finally
{
}
