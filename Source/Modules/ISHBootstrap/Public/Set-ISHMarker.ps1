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
    Set a marker on the system
.DESCRIPTION
    Set ta marker (key/value) on the system.
    This marker can later be used in the Recipe (Get-ISHMarker/Test-ISHMarker) to drive specific customizations and/or configuration changes.
.PARAMETER Name
    Marker name
.PARAMETER Value
    Marker value. Usually empty.
.EXAMPLE
    Set-ISHMarker -Name name
.EXAMPLE
    Set-ISHMarker -Name name -Value value
#>
Function Set-ISHMarker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        $Value = $null
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        Set-JSON @PSBoundParameters -Type Marker
    }

    end {

    }
}
