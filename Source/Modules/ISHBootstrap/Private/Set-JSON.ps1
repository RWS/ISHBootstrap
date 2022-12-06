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
   Set the values in the json file
.DESCRIPTION
   Set the values in the json file
.EXAMPLE
   Set-JSON -Type Tag -Name name -Value value # Set the tag
.EXAMPLE
   Set-JSON -Type Marker -Name name -Value value # Set the value for the marker
#>
Function Set-JSON {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        $Value = $null,
        [Parameter(Mandatory = $true)]
        [string]$Type,
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $commonJSONParameters = @{ } + $PSBoundParameters
        $null = $commonJSONParameters.Remove("Name")
        $null = $commonJSONParameters.Remove("Value")
    }

    process {
        Write-Debug "Updating JSON for Type=$Type"
        $json = Get-JSONContent @commonJSONParameters
        if ($json | Get-Member -Name $Name) {
            $json.$Name = $Value
            Write-Verbose "Updated item with Name=$Name"
        }
        else {
            $json | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
            Write-Verbose "Added item with Name=$Name"
        }
    }

    end {
        Set-JSONContent -JSON $json @commonJSONParameters
        Write-Verbose "Updated JSON for Type=$Type"
    }
}
