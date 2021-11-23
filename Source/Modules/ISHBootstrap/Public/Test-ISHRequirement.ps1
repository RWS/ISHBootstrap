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
    Test if the system meets a requirement
.DESCRIPTION
    A requirement can be
    - A module is installed
    - A marker is set
    - A tag is set
    - A component tag is set
    - A product version is installed
.EXAMPLE
    Test-ISHRequirement -Name name -Marker
.EXAMPLE
    Test-ISHRequirement -Name name -Value value -Marker
.EXAMPLE
    Test-ISHRequirement -Name name -tag
.EXAMPLE
    Test-ISHRequirement -Name name -Value value -tag
.EXAMPLE
    Test-ISHRequirement -Name DatabaseUpgrade -ISH
.EXAMPLE
    Test-ISHRequirement -Name BackgroundTask -BackgrountTaskRole Default -ISH
.EXAMPLE
    Test-ISHRequirement -Major 13 -ISH
#>
Function Test-ISHRequirement {
    [OutputType([Boolean])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Module")]
        [Parameter(Mandatory = $true, ParameterSetName = "Marker")]
        [Parameter(Mandatory = $true, ParameterSetName = "Tag")]
        [Parameter(Mandatory = $true, ParameterSetName = "ISH Component")]
        [Parameter(Mandatory = $true, ParameterSetName = "ISH BackgroundTask")]
        [string]$Name,
        [Parameter(Mandatory = $true, ParameterSetName = "Module")]
        [switch]$Module,
        [Parameter(Mandatory = $false, ParameterSetName = "Module")]
        [string]$MaximumVersion = $null,
        [Parameter(Mandatory = $false, ParameterSetName = "Module")]
        [string]$MinimumVersion = $null,
        [Parameter(Mandatory = $true, ParameterSetName = "Marker")]
        [switch]$Marker,
        [Parameter(Mandatory = $true, ParameterSetName = "Tag")]
        [switch]$Tag,
        [Parameter(Mandatory = $false, ParameterSetName = "Marker")]
        [Parameter(Mandatory = $false, ParameterSetName = "Tag")]
        [string]$Value = $null,
        [Parameter(Mandatory = $true, ParameterSetName = "ISH Component")]
        [Parameter(Mandatory = $true, ParameterSetName = "ISH BackgroundTask")]
        [Parameter(Mandatory = $true, ParameterSetName = "ISH Version")]
        [switch]$ISH,
        [Parameter(Mandatory = $true, ParameterSetName = "ISH BackgroundTask")]
        [switch]$BackgrountTaskRole,
        [Parameter(Mandatory = $true, ParameterSetName = "ISH Version")]
        [string]$Major,
        [Parameter(Mandatory = $false, ParameterSetName = "ISH Version")]
        [string]$Minor = $null,
        [Parameter(Mandatory = $false, ParameterSetName = "ISH Version")]
        [string]$Build = $null,
        [Parameter(Mandatory = $false, ParameterSetName = "ISH Version")]
        [string]$Revision = $null,
        [Parameter(Mandatory = $false, ParameterSetName = "Module")]
        [Parameter(Mandatory = $false, ParameterSetName = "Marker")]
        [Parameter(Mandatory = $false, ParameterSetName = "Tag")]
        [Parameter(Mandatory = $false, ParameterSetName = "ISH Component")]
        [Parameter(Mandatory = $false, ParameterSetName = "ISH BackgroundTask")]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $ISHDeploymentNameSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentNameSplat = @{Name = $ISHDeployment}
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Module' {
                $localModules = Get-Module -Name $Name -ListAvailable | Sort-Object -Descending Version
                if (-not $localModules) {
                    $false
                }
                elseif ($MaximumVersion) {
                    ($localModules | Select-Object -First 1 -ExpandProperty Version) -le $MaximumVersion
                }
                elseif ($MinimumVersion) {
                    ($localModules | Select-Object -Last 1 -ExpandProperty Version) -ge $MinimumVersion
                }
                else {
                    $true
                }
            }
            'Marker' {
                if (Test-ISHMarker -Name $Name) {
                    if ($Value) {
                        (Get-ISHMarker -Name $Name) -eq $Value
                    }
                    else {
                        $true
                    }
                }
                else {
                    $false
                }
            }
            'Tag' {
                if (Test-Tag -Name $Name) {
                    if ($Value) {
                        (Get-ISHTag -Name $Name) -eq $Value
                    }
                    else {
                        $true
                    }
                }
                else {
                    $false
                }
            }
            'ISH Component' {
                Test-ISHComponent -Name $Name
            }
            'ISH BackgroundTask' {
                Test-ISHComponent -Name BackgroundTask -Role $Name -ErrorAction SilentlyContinue
            }
            'ISH Version' {
                $deployment = Get-ISHDeployment @ISHDeploymentNameSplat
                $versionMatch = $Major -eq $deployment.SoftwareVersion.Major
                if ($Minor) {
                    $versionMatch = $versionMatch -and ($Minor -eq $deployment.SoftwareVersion.Minor)
                }
                if ($Build) {
                    $versionMatch = $versionMatch -and ($Build -eq $deployment.SoftwareVersion.Build)
                }
                if ($Revision) {
                    $versionMatch = $versionMatch -and ($Revision -eq $deployment.SoftwareVersion.Revision)
                }
                $versionMatch
            }
        }
    }

    end {

    }
}
