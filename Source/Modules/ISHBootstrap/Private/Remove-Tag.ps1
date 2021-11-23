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
   Remove existing tag
.DESCRIPTION
   Remove existing tag
.EXAMPLE
   Remove-Tag -Name name
#>
function Remove-Tag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $useEC2Tag = (Test-RunOnEC2) -and (-not (Test-JSONContent -Type Tag))
        Write-Debug "useEC2Tag=$useEC2Tag"

        if ($useEC2Tag) {
            Remove-TagEC2 @PSBoundParameters
        }
        else {
            Remove-JSON @PSBoundParameters -Type Tag
        }
    }

    end {

    }
}
