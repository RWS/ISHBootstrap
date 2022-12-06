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
    Invoke the deployment sequence.
.DESCRIPTION
    This cmdlet sequentually execute deployment steps in proper order.
.PARAMETER RecipeFolderPath
    Path to the recipe directory which contains recipe manifest file.
.PARAMETER ISHDeployment
    Specifies the name or instance of the Content Manager deployment. See Get-ISHDeployment for more details.
.EXAMPLE
    Invoke-ISHDeploymentSequence -RecipeFolderPath RecipeFolderPath -ISHDeployment InfoShareInstanceN
#>
Function Invoke-ISHDeploymentSequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RecipeFolderPath,
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $newBoundParameters = @{ } + $PSBoundParameters
    }

    process {
        Write-Debug $env:PSModulePath
        Invoke-ISHDeploymentStep -ApplicationStop @newBoundParameters

        Invoke-ISHDeploymentStep -BeforeInstall @newBoundParameters

        Invoke-ISHDeploymentStep -AfterInstall @newBoundParameters

        Invoke-ISHDeploymentStep -ApplicationStart @newBoundParameters

        Invoke-ISHDeploymentStep -ValidateService @newBoundParameters
    }

    end {

    }
}
