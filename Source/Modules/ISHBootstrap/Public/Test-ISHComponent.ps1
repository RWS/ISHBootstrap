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
   Test if the system is configured with the component
.DESCRIPTION
   Test if the system is configured with the component
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
        [string]$Role
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $tagNamePrefix = "ISHComponent-"
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Not BackgroundTask' {
                Test-Tag -Name "$tagNamePrefix$Name"
            }
            'BackgroundTask' {
                if (Test-Tag -Name "$tagNamePrefix$Name") {
                    $roles = (Get-Tag -Name "$tagNamePrefix$Name") -split ','
                }
                $roles -contains $Role
            }
        }
    }

    end {

    }
}
