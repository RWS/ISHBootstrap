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
    For choosen role set all required component tags on local system.
.DESCRIPTION
    For choosen role set all required component tags on local system.
.PARAMETER AllInOne
    Install everything on one host.
.PARAMETER OneBE
    Single backend role where background task with multiple roles will be running.
.PARAMETER MultipleFE
    Role for multiple frontends which will work with single backend.
.PARAMETER MultipleBEMulti
    Backend where background with Multi role is running.
.PARAMETER OneBESingle
    Backend where background with Single role is running.
.PARAMETER ISHVersion
    Product version, by default softwareversion deployment parameter will be used.
.PARAMETER ISHDeployment
    Specifies the name or instance of the Content Manager deployment. See Get-ISHDeployment for more details.
.EXAMPLE
    Set-ISHRoleComponentTags -AllInOne
.EXAMPLE
    Set-ISHRoleComponentTags -OneBE -MultipleFE
#>
Function Set-ISHRoleComponentTags {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = "AllInOne")]
        [switch]$AllInOne = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "OneBE-MultipleFE")]
        [switch]$OneBE = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "OneBE-MultipleFE")]
        [Parameter(Mandatory = $false, ParameterSetName = "MultipleBEMulti-OneBESingle-MultipleFE")]
        [switch]$MultipleFE = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "MultipleBEMulti-OneBESingle-MultipleFE")]
        [switch]$MultipleBEMulti = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "MultipleBEMulti-OneBESingle-MultipleFE")]
        [switch]$OneBESingle = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "AllInOne")]
        [Parameter(Mandatory = $false, ParameterSetName = "OneBE-MultipleFE")]
        [Parameter(Mandatory = $false, ParameterSetName = "MultipleBEMulti-OneBESingle-MultipleFE")]
        [string]$ISHVersion,
        [Parameter(Mandatory = $false, ParameterSetName = "AllInOne")]
        [Parameter(Mandatory = $false, ParameterSetName = "OneBE-MultipleFE")]
        [Parameter(Mandatory = $false, ParameterSetName = "MultipleBEMulti-OneBESingle-MultipleFE")]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
        if(-not $ISHVersion){
            $ISHVersion = Get-ISHDeploymentParameters -Name softwareversion -ValueOnly @ISHDeploymentSplat
        }
    }

    process {
        if ($AllInOne) {
            Set-ISHComponent -All -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -BackgroundTask -Role @("Multi", "Single") @ISHDeploymentSplat
            Set-Tag -Name "ISHRole" -Value "AllInOne" @ISHDeploymentSplat
        }

        if ($OneBE) {
            Set-ISHComponent -All -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -BackgroundTask -Role @("Multi", "Single") @ISHDeploymentSplat

            Set-Tag -Name "ISHRole" -Value "OneBE" @ISHDeploymentSplat
        }

        if ($MultipleFE) {
            Set-ISHComponent -Web -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -WebCS -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -FontoContentQuality -ISHVersion $ISHVersion @ISHDeploymentSplat
            if ($ISHVersion -eq '14.0.2')
            {
                Set-ISHComponent -FontoDeltaXml -ISHVersion $ISHVersion @ISHDeploymentSplat
            }
            Set-ISHComponent -FontoDocumentHistory -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -FontoReview -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -FontoSpellChecker -ISHVersion $ISHVersion @ISHDeploymentSplat

            Set-Tag -Name "ISHRole" -Value "MultipleFE" @ISHDeploymentSplat
        }

        if ($MultipleBEMulti) {
            Set-ISHComponent -Web -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -WebCS -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -FontoContentQuality -ISHVersion $ISHVersion @ISHDeploymentSplat
            if ($ISHVersion -eq '14.0.2')
            {
                Set-ISHComponent -FontoDeltaXml -ISHVersion $ISHVersion @ISHDeploymentSplat
            }
            Set-ISHComponent -FontoDocumentHistory -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -FontoReview -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -FontoSpellChecker -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -TranslationBuilder -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -TranslationOrganizer -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -All -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -BackgroundTask -Role 'Multi' @ISHDeploymentSplat

            Set-Tag -Name "ISHRole" -Value "MultipleBEMulti" @ISHDeploymentSplat
        }

        if ($OneBESingle) {
            Set-ISHComponent -Web -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -WebCS -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -FontoContentQuality -ISHVersion $ISHVersion @ISHDeploymentSplat
            if ($ISHVersion -eq '14.0.2')
            {
                Set-ISHComponent -FontoDeltaXml -ISHVersion $ISHVersion @ISHDeploymentSplat
            }
            Set-ISHComponent -FontoDocumentHistory -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -FontoReview -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -FontoSpellChecker -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -DatabaseUpgrade -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -FullTextIndex -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -Crawler -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -All -ISHVersion $ISHVersion @ISHDeploymentSplat
            Set-ISHComponent -BackgroundTask -Role 'Single' @ISHDeploymentSplat

            Set-Tag -Name "ISHRole" -Value "OneBESingle" @ISHDeploymentSplat
        }

    }

    end {

    }
}
