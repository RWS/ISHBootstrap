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
   Starts the web application pools for all web applications: ISHCM, (ISHCS,) ISHSTS and ISHWS
.DESCRIPTION
   Starts the web application pools for all web applications: ISHCM, (ISHCS,) ISHSTS and ISHWS
   This is only for internal purposes and beyond the scope of the component manager
.EXAMPLE
   Start-ISHWeb
.Link
   Stop-ISHWeb
#>
Function Start-ISHWeb {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
    }

    process {

        Get-ISHDeploymentParameters @ISHDeploymentSplat| Where-Object -Property Name -Like "infoshare*webappname" | ForEach-Object {
            $appPoolName = "TrisoftAppPool$($_.Value)"
            Write-Debug "appPoolName=$appPoolName"

            Write-Debug "Starting web app pool $appPoolName"
            Start-WebAppPool -Name $appPoolName
            Write-Verbose "Started web app pool $appPoolName"
        }
    }

    end {

    }
}
