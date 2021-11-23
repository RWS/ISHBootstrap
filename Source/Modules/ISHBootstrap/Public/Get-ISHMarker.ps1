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
    Return one or multiple markers from the system.
.DESCRIPTION
    Returns one or multiple markers from the system.
    Marker values can be used in the Recipe to drive specific customizations and/or configuration changes.
.PARAMETER Name
    Marker name. Return all markers available if not specified.
.EXAMPLE
    Get-ISHMarker
.EXAMPLE
    Get-ISHMarker -Name MarkerName
#>
Function Get-ISHMarker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Name = $null
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        Get-JSON @PSBoundParameters -Type Marker
    }

    end {

    }
}
