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
   Get the key
.DESCRIPTION
   Get the key
.EXAMPLE
   Get-DebugReroute -ProjectStage
#>
function Get-DebugReroute {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Project")]
        [switch]$ProjectStage,
        [Parameter(Mandatory = $true, ParameterSetName = "ISH")]
        [switch]$ISH,
        [Parameter(Mandatory = $true, ParameterSetName = "Custom")]
        [switch]$Custom,
        [Parameter(Mandatory = $false, ParameterSetName = "Project")]
        [Parameter(Mandatory = $false, ParameterSetName = "ISH")]
        [Parameter(Mandatory = $false, ParameterSetName = "Custom")]
        [string]$ISHDeployment
    )

    begin {
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
        $debugKey = Get-Key -DebugReroute @ISHDeploymentSplat
        Write-Debug "debugKey=$debugKey"
        $deploymentConfigFilePath = (Get-Variable -Name "ISHDeploymentConfigFilePath").Value -f ($ISHDeployment  -replace "^InfoShare$")
        Write-Debug "deploymentConfig=$deploymentConfigFilePath"
    }

    process {
        Write-Verbose "Testing if $debug key exists"
        if (Test-KeyValuePS -Folder $debugKey -FilePath $deploymentConfigFilePath) {
            Write-Debug "$debug key found. Getting value"
            $debugValues = Get-KeyValuePS -Key $debugKey -Recurse -FilePath $deploymentConfigFilePath

            $rerouteKey = $PSCmdlet.ParameterSetName
            Write-Debug "$rerouteKey=$rerouteKey"
            if (($rerouteKey -eq 'ISH') -or ($rerouteKey -eq 'Custom')) {
                $rerouteKey = "Project"
            }
            Write-Debug "$rerouteKey=$rerouteKey"

            Write-Verbose "Retrieving key $debugKey/Reroute/$rerouteKey"
            $debugValues | Where-Object -Property Key -EQ "$debugKey/Reroute/$rerouteKey" | Select-Object -ExpandProperty Value
        }
        else {
            Write-Debug "$debug key not found"
            $null
        }
    }

    end {

    }
}
