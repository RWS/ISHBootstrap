<#
# Copyright (c) 2021 All Rights Reserved by the SDL Group.
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
   Invokes the ishbootstrap sequence for the deployment step/hook
.DESCRIPTION
   Initiates the ishbootstrap flow that match the specific deployment step/hook
.EXAMPLE
   Invoke-ISHDeploymentStep -ApplicationStop -RootPath rootpath
.EXAMPLE
   Invoke-ISHDeploymentStep -BeforeInstall -RootPath rootpath
.EXAMPLE
   Invoke-ISHDeploymentStep -AfterInstall -RootPath rootpath
.EXAMPLE
   Invoke-ISHDeploymentStep -ApplicationStart -RootPath rootpath
.EXAMPLE
   Invoke-ISHDeploymentStep -ValidateService -RootPath rootpath
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
        [string]$RootPath
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
