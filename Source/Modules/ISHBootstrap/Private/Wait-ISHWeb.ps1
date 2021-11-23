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
   Wait for the ISH Web Components to become ready
.DESCRIPTION
   Wait for the ISH Web Components to become ready
.EXAMPLE
   Wait-ISHWeb
.Link
   Wait-ISHWeb
#>
Function Wait-ISHWeb {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        $ISHDeploymentNameSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentNameSplat = @{Name = $ISHDeployment}
        }
    }

    process {
        $deployment = Get-ISHDeployment @ISHDeploymentNameSplat
        $urisToWaitFor = @(
            @{
                Uri    = "https://localhost/"
                Status = 200
            }
            @{
                Uri    = "https://localhost/$($deployment.WebAppNameCM)/"
                Status = 302
            }
            @{
                Uri    = "https://localhost/$($deployment.WebAppNameWS)/ConnectionConfiguration.xml"
                Status = 200
            }
            @{
                Uri    = "https://localhost/$($deployment.WebAppNameWS)/Application25.asmx"
                Status = 200
            }
            @{
                Uri    = "https://localhost/$($deployment.WebAppNameWS)/Wcf/API25/Application.svc"
                Status = 200
            }
            @{
                Uri    = "https://localhost/$($deployment.WebAppNameSTS)/"
                Status = 200
            }
        )

        if ($deployment.WebAppNameCS) {
            $urisToWaitFor += @(
                @{
                    Uri    = "https://localhost/$($deployment.WebAppNameCS)/"
                    Status = 302
                }
            )
        }
        $urisToWaitFor | ForEach-Object {
            Write-Verbose "Waiting for $($_.Uri) to respond with status $($_.Status)."
            $splat = $_
            Wait-UriStatus @splat -MilliSeconds 500
        }
    }

    end {

    }
}
