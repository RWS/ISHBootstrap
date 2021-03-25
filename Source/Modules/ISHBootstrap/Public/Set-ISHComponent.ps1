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
   Configures the system with components
.DESCRIPTION
   When not hosted on EC2 use this cmdlet to create local component configuration
.EXAMPLE
   Set-ISHComponent -DatabaseUpgrade
.EXAMPLE
   Set-ISHComponent -DatabaseUpgrade -Crawler
.EXAMPLE
   Set-ISHComponent -BackgroundTask
.EXAMPLE
   Set-ISHComponent -BackgroundTask -Role Publish
#>
Function Set-ISHComponent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$DatabaseUpgrade = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$Web = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$WebCS = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$Crawler = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$FullTextIndex = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$TranslationJob = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$TranslationBuilder = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$TranslationOrganizer = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$FontoContentQuality = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$FontoDeltaXml = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$FontoDocumentHistory = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$FontoReview = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [switch]$FontoSpellChecker = $false,
        [Parameter(Mandatory = $true, ParameterSetName = "BackgroundTask")]
        [switch]$BackgroundTask = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "BackgroundTask")]
        [string[]]$Role = @("Default"),
        [Parameter(Mandatory = $true, ParameterSetName = "All")]
        [switch]$All = $false
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $tagNamePrefix = "ISHComponent"
        if ($DatabaseUpgrade -or $All) {
            Set-Tag -Name "$tagNamePrefix-DatabaseUpgrade"
        }
        if ($Web -or $All) {
            Set-Tag -Name "$tagNamePrefix-CM"
            Set-Tag -Name "$tagNamePrefix-WS"
            Set-Tag -Name "$tagNamePrefix-STS"
        }
        if ($WebCS -or $All) {
            Set-Tag -Name "$tagNamePrefix-CS"
        }
        if ($Crawler -or $All) {
            Set-Tag -Name "$tagNamePrefix-Crawler"
        }
        if ($FullTextIndex -or $All) {
            Set-Tag -Name "$tagNamePrefix-FullTextIndex"
        }
        if ($TranslationBuilder -or $All) {
            Set-Tag -Name "$tagNamePrefix-TranslationBuilder"
        }
        if ($TranslationOrganizer -or $All) {
            Set-Tag -Name "$tagNamePrefix-TranslationOrganizer"
        }
        if ($TranslationJob -or $All) {
            Set-Tag -Name "$tagNamePrefix-TranslationJob"
        }
        if ($FontoContentQuality -or $All) {
            Set-Tag -Name "$tagNamePrefix-FontoContentQuality"
        }
        if ($FontoDeltaXml -or $All) {
            Set-Tag -Name "$tagNamePrefix-FontoDeltaXml"
        }
        if ($FontoDocumentHistory -or $All) {
            Set-Tag -Name "$tagNamePrefix-FontoDocumentHistory"
        }
        if ($FontoReview -or $All) {
            Set-Tag -Name "$tagNamePrefix-FontoReview"
        }
        if ($FontoSpellChecker -or $All) {
            Set-Tag -Name "$tagNamePrefix-FontoSpellChecker"
        }
        if ($BackgroundTask -or $All) {
            Set-Tag -Name "$tagNamePrefix-BackgroundTask" -Value ($Role -join ',')
        }
    }

    end {

    }
}
