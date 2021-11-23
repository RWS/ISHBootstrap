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
   Test the values in the json file
.DESCRIPTION
   Test the values in the json file
.EXAMPLE
   Test-JSON -Type Tag -Name name # Test a tag
.EXAMPLE
   Test-JSON -Type Marker -Name name # Test a marker
#>
Function Test-JSON {
    [OutputType([Boolean])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $commonJSONParameters = @{ } + $PSBoundParameters
        $null = $commonJSONParameters.Remove("Name")
    }

    process {
        $json = Get-JSONContent @commonJSONParameters
        if ($json | Get-Member -Name $Name) {
            $true
        }
        else {
            $false
        }
    }

    end {

    }
}
