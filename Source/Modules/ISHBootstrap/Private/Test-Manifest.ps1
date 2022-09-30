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
   Test if the manifest is valid
.DESCRIPTION
   Test if the manifest is one of the ISHRecipe, ISHCoreHotfix or ISHHotfix
.EXAMPLE
   Test-Manifest -Path path
#>
Function Test-Manifest {
    [OutputType([Boolean])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $manifestPath = Split-Path $Path -Parent
        Write-Debug "manifestPath=$manifestPath"

        $manifestContent = Get-Content -Path $Path -Raw
        $manifestHash = Invoke-Expression -Command $manifestContent

    }

    process {
        $validType = $false
        $validPublish = $false

        if ($manifestHash.ContainsKey("Type")) {
            Write-Debug "manifestHash.Type=$($manifestHash.Type)"
            $validType = $manifestHash.Type -in @("ISHRecipe", "ISHCoreHotfix", "ISHHotfix")
        }
        else {
            Write-Debug "Does not contain Type"
        }

        if ($manifestHash.ContainsKey("Publish")) {
            $validPublish = $manifestHash.Publish.Contains("Name") -and $manifestHash.Publish.Contains("Version") -and $manifestHash.Publish.Contains("Date") -and $manifestHash.Publish.Contains("Engine")
        }
        else {
            Write-Debug "Does not contain publish metadata"
        }

        $validType -and $validPublish
    }

    end {

    }
}
