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
   Get the content of the json
.DESCRIPTION
   Get the content of the json based on the requested type
.EXAMPLE
   Get-JSONContent -Type type
#>
function Get-JSONContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    begin {
        $commonJSONParameters = @{ } + $PSBoundParameters
        Write-Debug "Type=$Type"
    }

    process {
        Write-Debug "Getting JSON for Type=$Type"
        $filePath = Get-JSONContentPath @commonJSONParameters
        Write-Debug "filePath=$filePath"

        if (Test-Path $filePath) {
            Write-Verbose "Getting content from $filePath"
            Get-Content -Path $filePath -Raw | ConvertFrom-Json
        }
        else {
            Write-Verbose "$filePath doesn't exist. Returning {}"
            "{}" | ConvertFrom-Json
        }


    }

    end {

    }
}
