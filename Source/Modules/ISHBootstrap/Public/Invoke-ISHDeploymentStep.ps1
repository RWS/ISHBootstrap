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

<#
.Synopsis
   Invoke deployment step.
.DESCRIPTION
   This cmdlet helper invoke separate deployment step which is defined by input parameter.
   Please see available parameters for detailed list of deployment steps.
.PARAMETER ApplicationStop
   During this step recipe code from StopBeforeCore and StopAfterCore will be executed.
   Also Stop-ISH comdlet will be called to stop core process.
.PARAMETER BeforeInstall
   Preparation step before product configuration.
.PARAMETER AfterInstall
   During this step core product and DB configuration is happening.
.PARAMETER ApplicationStart
   During this step recipe code from StartBeforeCore and StartAfterCore will be executed.
.PARAMETER ValidateService
   Execute Validation code from the recipe.
.PARAMETER RecipeFolderPath
   Path to the recipe directory which contains recipe manifest file.
.PARAMETER ISHDeployment
   Specifies the name or instance of the Content Manager deployment. See Get-ISHDeployment for more details.
.EXAMPLE
   Invoke-ISHDeploymentStep -ApplicationStop -RecipeFolderPath RecipeFolderPath -ISHDeployment InfoShareInstanceN
.EXAMPLE
   Invoke-ISHDeploymentStep -BeforeInstall -RecipeFolderPath RecipeFolderPath -ISHDeployment InfoShareInstanceN
.EXAMPLE
   Invoke-ISHDeploymentStep -AfterInstall -RecipeFolderPath RecipeFolderPath -ISHDeployment InfoShareInstanceN
.EXAMPLE
   Invoke-ISHDeploymentStep -ApplicationStart -RecipeFolderPath RecipeFolderPath -ISHDeployment InfoShareInstanceN
.EXAMPLE
   Invoke-ISHDeploymentStep -ValidateService -RecipeFolderPath RecipeFolderPath -ISHDeployment InfoShareInstanceN
#>
Function Invoke-ISHDeploymentStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "ApplicationStop")]
        [switch]$ApplicationStop,
        [Parameter(Mandatory = $true, ParameterSetName = "BeforeInstall")]
        [switch]$BeforeInstall,
        [Parameter(Mandatory = $true, ParameterSetName = "AfterInstall")]
        [switch]$AfterInstall,
        [Parameter(Mandatory = $true, ParameterSetName = "ApplicationStart")]
        [switch]$ApplicationStart,
        [Parameter(Mandatory = $true, ParameterSetName = "ValidateService")]
        [switch]$ValidateService,
        [Parameter(Mandatory = $true, ParameterSetName = "ApplicationStop")]
        [Parameter(Mandatory = $true, ParameterSetName = "BeforeInstall")]
        [Parameter(Mandatory = $true, ParameterSetName = "AfterInstall")]
        [Parameter(Mandatory = $true, ParameterSetName = "ApplicationStart")]
        [Parameter(Mandatory = $true, ParameterSetName = "ValidateService")]
        [string]$RecipeFolderPath,
        [Parameter(Mandatory = $false, ParameterSetName = "ApplicationStop")]
        [Parameter(Mandatory = $false, ParameterSetName = "BeforeInstall")]
        [Parameter(Mandatory = $false, ParameterSetName = "AfterInstall")]
        [Parameter(Mandatory = $false, ParameterSetName = "ApplicationStart")]
        [Parameter(Mandatory = $false, ParameterSetName = "ValidateService")]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $newBoundParameters = @{ } + $PSBoundParameters
    }

    process {
        Invoke-ISHCodeDeployHook @newBoundParameters
    }

    end {

    }
}
