<#
# Copyright (c) 2021 All Rights Reserved by the SDL Group.
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
   Get the tag or multiple tags
.DESCRIPTION
   Get the tag or multiple tags
.EXAMPLE
   Get-Tag
.EXAMPLE
   Get-Tag -Name name
#>
function Get-Tag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name = $null
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $useEC2Tag = (Test-RunOnEC2) -and (-not (Test-JSONContent -Type LocalTag))
        Write-Debug "useEC2Tag=$useEC2Tag"

        if ($useEC2Tag) {
            $tags = Get-TagEC2
        }
        else {
            $tags = Get-JSON -Type LocalTag
        }

        if ($Name) {
            $tags | Where-Object -Property Name -EQ $Name | Select-Object -ExpandProperty Value
        }
        else {
            $tags
        }
    }

    end {

    }
}
