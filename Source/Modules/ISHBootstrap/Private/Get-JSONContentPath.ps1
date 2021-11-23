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
   Get the path of the json file
.DESCRIPTION
   Get the path of the json file based on the requested type
.EXAMPLE
   Get-JSONContentPath -Type type
#>
function Get-JSONContentPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    begin {
        Write-Debug "Type=$Type"
        $moduleStagePath = Get-StageFolderPath
        Write-Debug "moduleStagePath=$moduleStagePath"
    }

    process {
        $path = Join-Path -Path $moduleStagePath -ChildPath "$Type.json"
        Write-Verbose "JSON content path is $path"
        $path
    }

    end {

    }
}
