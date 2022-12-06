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
    Test if component is set for current system.
.DESCRIPTION
    This cmdelt verify if corresponding component tag is set.
    Each component represent separate feature of the product.
.EXAMPLE
    Test-ISHComponent -Name "DatabaseUpgrade"
.EXAMPLE
    Test-ISHComponent -Name "BackgroundTask" -Role Default
#>
Function Test-ISHComponent {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Not BackgroundTask")]
        [Parameter(Mandatory = $true, ParameterSetName = "BackgroundTask")]
        [ValidateSet("DatabaseUpgrade", "CM", "CS", "WS", "STS", "Crawler", "FullTextIndex", "TranslationBuilder", "TranslationOrganizer", "BackgroundTask", "FontoContentQuality", "FontoDeltaXml", "FontoDocumentHistory", "FontoReview", "FontoSpellChecker")]
        [string]$Name,
        [Parameter(Mandatory = $true, ParameterSetName = "BackgroundTask")]
        [string]$Role,
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
        $tagNamePrefix = "ISHComponent-"
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Not BackgroundTask' {
                Test-Tag -Name "$tagNamePrefix$Name" @ISHDeploymentSplat
            }
            'BackgroundTask' {
                if (Test-Tag -Name "$tagNamePrefix$Name" @ISHDeploymentSplat) {
                    $roles = (Get-ISHTag -Name "$tagNamePrefix$Name" @ISHDeploymentSplat) -split ','
                }
                $roles -contains $Role
            }
        }
    }

    end {

    }
}
