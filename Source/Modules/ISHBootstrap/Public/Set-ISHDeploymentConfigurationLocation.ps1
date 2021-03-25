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
    Set variable which contains path to the Deployment Configuration file
.DESCRIPTION
    Set variable which contains path to the Deployment Configuration file
.EXAMPLE
    Set-ISHDeploymentConfigurationLocation -Path 'C:\config-docs-project.json'
#>
Function Set-ISHDeploymentConfigurationLocation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        Write-Debug "New locatoion=$Path"
        if (Test-Path -Path $Path) {
            Set-Variable -Name 'ISHDeployemntConfigFile' -Value $Path
        }
        else {
            throw "Can not set '$Path' as configuration file location. Path do not exist."
        }
    }

    end {

    }
}
