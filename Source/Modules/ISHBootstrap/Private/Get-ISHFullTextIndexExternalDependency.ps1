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

<#
.Synopsis
   Get the dependency to FullTextIndex component
.DESCRIPTION
   Get the dependency to FullTextIndex component (Local, ExternalEC2, None)
.EXAMPLE
   Get-ISHFullTextIndexExternalDependency
#>
Function Get-ISHFullTextIndexExternalDependency {
    [CmdletBinding()]
    [OutputType([String])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
    }

    process {
        # Check if the host is on EC2. When on EC2 check if the FullTextIndex component is also enabled
        # When the the host is on EC2 and the FullTextIndex component is disabled, the dependency is ExternalEC2
        # When the the host is on EC2 and the FullTextIndex component is enabled, the dependency is Local
        # When the the host is not on EC2 and the FullTextIndex component is disabled, the dependency is None
        # When the the host is not on EC2 and the FullTextIndex component is enabled, the dependency is Local
        $isHostedOnEC2 = Test-RunOnEC2
        Write-Debug "isHostedOnEC2=$isHostedOnEC2"
        $isFullTextIndexEnabled = Test-ISHComponent -Name FullTextIndex @ISHDeploymentSplat
        Write-Debug "isFullTextIndexEnabled=$isFullTextIndexEnabled"

        if ($isHostedOnEC2 -and $isFullTextIndexEnabled) {
            $dependency = "Local"
        }
        elseif ($isHostedOnEC2 -and (-not ($isFullTextIndexEnabled))) {
            $dependency = "ExternalEC2"
        }
        elseif ((-not $isHostedOnEC2) -and $isFullTextIndexEnabled) {
            $dependency = "Local"
        }
        else {
            $dependency = "None"
        }

        Write-Debug "dependency=$dependency"
        Write-Verbose "FullTextIndex dependency is $dependency"
        $dependency
    }

    end {

    }
}
