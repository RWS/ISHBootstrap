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
   Set the content of the json
.DESCRIPTION
   Set the content of the json based on the requested type
.EXAMPLE
   Set-JSONContent -JSON $json -Type Tag
.EXAMPLE
   Set-JSONContent -JSON $json -Type Marker
#>
function Set-JSONContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$JSON,
        [Parameter(Mandatory = $true)]
        [string]$Type,
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $commonJSONParameters = @{ } + $PSBoundParameters
        $null = $commonJSONParameters.Remove("JSON")
    }

    process {
        Write-Debug "Getting JSON for Type=$Type"
        $filePath = Get-JSONContentPath @commonJSONParameters
        Write-Debug "filePath=$filePath"

        if (-not (Test-Path -Path $filePath)) {
            $null = New-Item -Path $filePath -ItemType File -Force
            Write-Verbose "Created $filePath"
        }
        $JSON | ConvertTo-Json | Format-Json | Out-File -FilePath $filePath -Force
        Write-Verbose "Updated $filePath"
    }

    end {

    }
}
