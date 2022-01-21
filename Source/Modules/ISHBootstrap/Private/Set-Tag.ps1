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
   Configures locally the system with the tag
.DESCRIPTION
   When not hosted on EC2 use this cmdlet to mimic a tag
.EXAMPLE
   Set-Tag -Name name
.EXAMPLE
   Set-Tag -Name name -Value value
#>
Function Set-Tag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Value = $null,
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $null = $newBoundParameters.Remove('Name')
        $null = $newBoundParameters.Remove('Value')
    }

    process {
        $useEC2Tag = (Test-RunOnEC2) -and (-not (Test-JSONContent @newBoundParameters -Type Tag))
        Write-Debug "useEC2Tag=$useEC2Tag"

        if ($useEC2Tag) {
            Set-TagEC2 @PSBoundParameters
        }
        else {
            Set-JSON @PSBoundParameters -Type Tag
        }
    }

    end {

    }
}
