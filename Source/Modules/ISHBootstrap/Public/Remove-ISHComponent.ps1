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
    Remove component tag from the system.
.DESCRIPTION
    This cmdlet removes selected component tags form the system.
    It do not remove components directly only corresponding tags
    which means that component will be removed during recipe execution.
.EXAMPLE
    Remove-ISHComponent -All
.EXAMPLE
    Remove-ISHComponent -DatabaseUpgrade -Crawler
.EXAMPLE
    Remove-ISHComponent -BackgroundTask
#>
Function Remove-ISHComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$DatabaseUpgrade = $false,
        [Parameter(Mandatory = $false)]
        [switch]$Web = $false,
        [Parameter(Mandatory = $false)]
        [switch]$WebCS = $false,
        [Parameter(Mandatory = $false)]
        [switch]$Crawler = $false,
        [Parameter(Mandatory = $false)]
        [switch]$FullTextIndex = $false,
        [Parameter(Mandatory = $false)]
        [switch]$TranslationJob = $false,
        [Parameter(Mandatory = $false)]
        [switch]$TranslationBuilder = $false,
        [Parameter(Mandatory = $false)]
        [switch]$TranslationOrganizer = $false,
        [Parameter(Mandatory = $false)]
        [switch]$FontoContentQuality = $false,
        [Parameter(Mandatory = $false)]
        [switch]$FontoDeltaXml = $false,
        [Parameter(Mandatory = $false)]
        [switch]$FontoDocumentHistory = $false,
        [Parameter(Mandatory = $false)]
        [switch]$FontoReview = $false,
        [Parameter(Mandatory = $false)]
        [switch]$FontoSpellChecker = $false,
        [Parameter(Mandatory = $false)]
        [switch]$BackgroundTask = $false,
        [Parameter(Mandatory = $false)]
        [switch]$All = $false,
        [Parameter(Mandatory = $false)]
        [string]$ISHVersion=$(Get-ISHDeploymentParameters -Name softwareversion  -ValueOnly)
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $tagNamePrefix = "ISHComponent"
        if ($DatabaseUpgrade -or $All) {
            Remove-Tag -Name "$tagNamePrefix-DatabaseUpgrade"
        }
        if ($Web -or $All) {
            Remove-Tag -Name "$tagNamePrefix-CM"
            Remove-Tag -Name "$tagNamePrefix-WS"
            Remove-Tag -Name "$tagNamePrefix-STS"
        }
        if ($WebCS -or $All) {
            Remove-Tag -Name "$tagNamePrefix-CS"
        }
        if ($Crawler -or $All) {
            Remove-Tag -Name "$tagNamePrefix-Crawler"
        }
        if ($FullTextIndex -or $All) {
            Remove-Tag -Name "$tagNamePrefix-FullTextIndex"
        }
        if ($TranslationBuilder -or $All) {
            Remove-Tag -Name "$tagNamePrefix-TranslationBuilder"
        }
        if ($TranslationOrganizer -or $All) {
            Remove-Tag -Name "$tagNamePrefix-TranslationOrganizer"
        }
        if ($TranslationJob -or $All) {
            Remove-Tag -Name "$tagNamePrefix-TranslationJob"
        }
        if ($FontoContentQuality -or $All) {
            Remove-Tag -Name "$tagNamePrefix-FontoContentQuality"
        }
        if ($FontoDeltaXml -or $All) {
            if ($ISHVersion -eq '14.0.2')
            {
                Remove-Tag -Name "$tagNamePrefix-FontoDeltaXml"
            }
            else
            {
                throw "FontoDeltaXml is not supported on ish version: $ISHVersion"
            }
        }
        if ($FontoDocumentHistory -or $All) {
            Remove-Tag -Name "$tagNamePrefix-FontoDocumentHistory"
        }
        if ($FontoReview -or $All) {
            Remove-Tag -Name "$tagNamePrefix-FontoReview"
        }
        if ($FontoSpellChecker -or $All) {
            Remove-Tag -Name "$tagNamePrefix-FontoSpellChecker"
        }
        if ($BackgroundTask -or $All) {
            Remove-Tag -Name "$tagNamePrefix-BackgroundTask"
        }
        if ($All) {
            Get-ISHTag | Where-Object { $_.Name -Like 'ISHComponent-*' } | ForEach-Object { Remove-Tag -Name $_.Name }
        }
    }

    end {

    }
}
