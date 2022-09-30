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
    Set component tag on the system.
.DESCRIPTION
    Create a tag or set of tags for selected component on current system.
    Components will be configurd during recipe execution based on tags set on the system.
.PARAMETER All
    Enable all avaliable components on local system for AllInOne deployment.
.PARAMETER DatabaseUpgrade
    Run database upgrade during deployment.
.PARAMETER Web
    Enable CM UI on local system.
.PARAMETER WebCS
    Enable CS on local system.
.PARAMETER Crawler
    Enable crawler on local system.
.PARAMETER FullTextIndex
    Enable full text indexer on local system.
.PARAMETER TranslationJob
    Enable translation job on local system.
.PARAMETER TranslationBuilder
    Enable translation builder on local system.
.PARAMETER TranslationOrganizer
    Enable translation organizer on local system.
.PARAMETER FontoContentQuality
    Enable Fonto ContentQuality integration on local system.
.PARAMETER FontoDeltaXml
    Enable Fonto DeltaXml integration on local system.
.PARAMETER FontoDocumentHistory
    Enable Fonto DocumentHistory integration on local system.
.PARAMETER FontoReview
    Enable Fonto Review integration on local system.
.PARAMETER FontoSpellChecker
    Enable Fonto SpellChecker integration on local system.
.PARAMETER BackgroundTask
    Enable background task on local system.
.PARAMETER Role
    Backgroud task role.
.PARAMETER ISHVersion
    Product version, by default softwareversion deployment parameter will be used.
.PARAMETER ISHDeployment
    Specifies the name or instance of the Content Manager deployment. See Get-ISHDeployment for more details.
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
        [string[]]$Role = @("Multi", "Single"),
        [Parameter(Mandatory = $true, ParameterSetName = "All")]
        [switch]$All = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [Parameter(Mandatory = $false, ParameterSetName = "All")]
        [string]$ISHVersion,
        [Parameter(Mandatory = $false, ParameterSetName = "All")]
        [Parameter(Mandatory = $false, ParameterSetName = "Not BackgroundTask")]
        [Parameter(Mandatory = $false, ParameterSetName = "BackgroundTask")]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
        if(-not $ISHVersion -and -not $BackgroundTask){
            $ISHVersion = Get-ISHDeploymentParameters -Name softwareversion -ValueOnly @ISHDeploymentSplat
        }
    }

    process {
        $tagNamePrefix = "ISHComponent"
        if ($DatabaseUpgrade -or $All) {
            Set-Tag -Name "$tagNamePrefix-DatabaseUpgrade" @ISHDeploymentSplat
        }
        if ($Web -or $All) {
            Set-Tag -Name "$tagNamePrefix-CM" @ISHDeploymentSplat
            Set-Tag -Name "$tagNamePrefix-WS" @ISHDeploymentSplat
            Set-Tag -Name "$tagNamePrefix-STS" @ISHDeploymentSplat
        }
        if ($WebCS -or $All) {
            Set-Tag -Name "$tagNamePrefix-CS" @ISHDeploymentSplat
        }
        if ($Crawler -or $All) {
            Set-Tag -Name "$tagNamePrefix-Crawler" @ISHDeploymentSplat
        }
        if ($FullTextIndex -or $All) {
            Set-Tag -Name "$tagNamePrefix-FullTextIndex" @ISHDeploymentSplat
        }
        if ($TranslationBuilder -or $All) {
            Set-Tag -Name "$tagNamePrefix-TranslationBuilder" @ISHDeploymentSplat
        }
        if ($TranslationOrganizer -or $All) {
            Set-Tag -Name "$tagNamePrefix-TranslationOrganizer" @ISHDeploymentSplat
        }
        if ($TranslationJob -or $All) {
            Set-Tag -Name "$tagNamePrefix-TranslationJob" @ISHDeploymentSplat
        }
        if ($FontoContentQuality -or $All) {
            Set-Tag -Name "$tagNamePrefix-FontoContentQuality" @ISHDeploymentSplat
        }
        if ($FontoDeltaXml -or $All) {
            if ($ISHVersion -eq '14.0.2')
            {
                Set-Tag -Name "$tagNamePrefix-FontoDeltaXml" @ISHDeploymentSplat
            }
            elseif($FontoDeltaXml)
            {
                throw "FontoDeltaXml is not supported on ish version: $ISHVersion"
            }
        }
        if ($FontoDocumentHistory -or $All) {
            Set-Tag -Name "$tagNamePrefix-FontoDocumentHistory" @ISHDeploymentSplat
        }
        if ($FontoReview -or $All) {
            Set-Tag -Name "$tagNamePrefix-FontoReview" @ISHDeploymentSplat
        }
        if ($FontoSpellChecker -or $All) {
            Set-Tag -Name "$tagNamePrefix-FontoSpellChecker" @ISHDeploymentSplat
        }
        if ($BackgroundTask -or $All) {
            Set-Tag -Name "$tagNamePrefix-BackgroundTask" -Value ($Role -join ',') @ISHDeploymentSplat
        }
    }

    end {

    }
}
