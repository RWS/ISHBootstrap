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
    Return one or multiple deployment tags from the system.
.DESCRIPTION
    Returns one or multiple deployment tags from the system.
    Tags are used in the deployment process to set different deployment condiotion for local system.
    Fore example for setting components. See Get-ISHComponents.
.PARAMETER Name
    Tag name. Return all tags available if not specified.
.PARAMETER ISHDeployment
    Specifies the name or instance of the Content Manager deployment. See Get-ISHDeployment for more details.
.EXAMPLE
    Get-ISHTag
.EXAMPLE
    Get-ISHTag -Name TagName
#>
function Get-ISHTag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name = $null,
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $newBoundParameters = @{ } + $PSBoundParameters
        $null = $newBoundParameters.Remove('Name')
    }

    process {
        $useEC2Tag = (Test-RunOnEC2) -and (-not (Test-JSONContent @newBoundParameters -Type Tag))
        Write-Debug "useEC2Tag=$useEC2Tag"

        if ($useEC2Tag) {
            $tags = Get-TagEC2
        }
        else {
            $tags = Get-JSON @newBoundParameters -Type Tag
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
