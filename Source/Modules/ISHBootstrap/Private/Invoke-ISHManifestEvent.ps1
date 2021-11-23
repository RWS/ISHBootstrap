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
   Invokes the script configured on an event from a manifest
.DESCRIPTION
   Invokes the script configured on an event from a manifest
.EXAMPLE
   Invoke-ISHManifestEvent -ManifestHash $manifestHash -EventName StopBeforeCore
#>
Function Invoke-ISHManifestEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$ManifestHash,
        [Parameter(Mandatory = $true)]
        [ValidateSet("PreRequisite", "StopBeforeCore", "StopAfterCore", "Execute", "DatabaseUpgradeBeforeCore", "DatabaseUpgradeAfterCore", "DatabaseUpdateBeforeCore", "DatabaseUpdateAfterCore", "StartBeforeCore", "StartAfterCore", "Validate")]
        [string]$EventName
    )

    begin {
        Write-Debug "EventName=$EventName"

    }

    process {
        if ($ManifestHash) {
            $path = $ManifestHash."$($EventName)Path"
            Write-Verbose "ManifestType:$($ManifestHash.Type) Event:$EventName Script:$path"
            if ($path) {
                Write-Debug "Invoking $path"
                $output = & $path
                Write-Verbose "Invoked $path"

                if ($output) {
                    Write-Warning "Script $path wrote unexpected output to the pipeline"
                    # Make sure that the output is a string
                    $out = $output | Out-String
                    Write-Host $out
                }
            }
        }
        else {
            Write-Debug "Manifest hash is empty"
        }
    }

    end {

    }
}
