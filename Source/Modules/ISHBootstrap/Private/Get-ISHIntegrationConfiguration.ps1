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
   Get integration configuration from parameter store for ISH
.DESCRIPTION
   Get integration configuration from parameter store for ISH. Consolidate the different values into one object
.EXAMPLE
   Get-ISHIntegrationConfiguration
#>
function Get-ISHIntegrationConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
        $projectStageKey = Get-Key -ProjectStage @ISHDeploymentSplat
        $ishKey = Get-Key -ISH @ISHDeploymentSplat
        Write-Debug "projectStageKey=$projectStageKey"
        Write-Debug "ishKey=$ishKey"
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
        $deploymentConfig = (Get-Variable -Name "ISHDeploymentConfigFilePath").Value -f ($ISHDeployment  -replace "^InfoShare$")
        Write-Debug "deploymentConfig=$deploymentConfig"
        $ISHVersion = Get-ISHDeploymentParameters -Name softwareversion -ValueOnly @ISHDeploymentSplat
    }

    process {
        $hash = @{
            XOPUS = $null
            FONTO = $null
            SITES = $null
            POOLPARTY = $null
            WORLDSERVER = $null
            TMS = $null
            SES = $null
        }

        #region - XOPUS
        $xopusKey = "$ishKey/Integration/XOPUS"
        Write-Debug "xopusKey=$xopusKey"
        $xopusIntegration = Test-KeyValuePS -Folder $xopusKey -FilePath $deploymentConfig
        if ($xopusIntegration -and ($ISHVersion -lt (New-Object 'Version' '14.0.1'))) {
            Write-Verbose "XOPUS integration information detected"
            Write-Debug "Retrieving recursevely from $xopusKey"
            $configurationValues = Get-KeyValuePS -Key $xopusKey -Recurse -FilePath $deploymentConfig
            $hash.XOPUS = @{
                Domain     = $configurationValues | Where-Object -Property Key -EQ "$xopusKey/Domain" | Select-Object -ExpandProperty Value
                LicenseKey = $configurationValues | Where-Object -Property Key -EQ "$xopusKey/LicenseKey" | Select-Object -ExpandProperty Value
            }
        }
        #endregion

        #region - FONTO
        $fontoKey = "$ishKey/Integration/FONTO"
        Write-Debug "fontoKey=$fontoKey"
        if (Test-KeyValuePS -Folder $fontoKey -FilePath $deploymentConfig) {
            Write-Verbose "FONTO integration information detected"
            Write-Debug "Retrieving $fontoKey subkeys for DraftSpace and ReviewSpace"

            $collectiveSpacesDocumentHistoryForDraftSpace = Test-KeyValuePS -Key "$fontoKey/DraftSpace/DocumentHistoryForDraftSpace" -FilePath $deploymentConfig
            if (-not ($collectiveSpacesDocumentHistoryForDraftSpace)) {
                $collectiveSpacesDraftSpace = Test-KeyValuePS -Key "$fontoKey/DraftSpace" -FilePath $deploymentConfig
            }
            else {
                $collectiveSpacesDraftSpace = $true
            }

            $collectiveSpacesDocumentHistoryForReviewSpace = Test-KeyValuePS -Key "$fontoKey/ReviewSpace/DocumentHistoryForReviewSpace" -FilePath $deploymentConfig
            $collectiveSpacesDocumentHistoryForReviewSpace = (($ISHVersion -gt (New-Object 'Version' '14.0.3')) -and $collectiveSpacesDocumentHistoryForReviewSpace)
            if (-not ($collectiveSpacesDocumentHistoryForReviewSpace)) {
                $collectiveSpacesReviewSpace = Test-KeyValuePS -Key "$fontoKey/ReviewSpace" -FilePath $deploymentConfig
            }
            else {
                $collectiveSpacesReviewSpace = $true
            }

            $hash.FONTO = @{
                CollectiveSpacesDocumentHistoryForDraftSpace = $collectiveSpacesDocumentHistoryForDraftSpace
                CollectiveSpacesDraftSpace                   = $collectiveSpacesDraftSpace
                CollectiveSpacesDocumentHistoryForReviewSpace = $collectiveSpacesDocumentHistoryForReviewSpace
                CollectiveSpacesReviewSpace                  = $collectiveSpacesReviewSpace
            }
        }
        #endregion

        #region - WORLDSERVER
        $wsKey = "$ishKey/Integration/WORLDSERVER"
        Write-Debug "wsKey=$wsKey"
        if (Test-KeyValuePS -Folder $wsKey -FilePath $deploymentConfig) {
            Write-Verbose "WORLDSERVER integration information detected"
            Write-Debug "Retrieving recursevely from $wsKey"
            $configurationValues = Get-KeyValuePS -Key $wsKey -Recurse -FilePath $deploymentConfig
            $hash.WORLDSERVER = @{
                apiUrl   = $configurationValues | Where-Object -Property Key -EQ "$wsKey/apiUrl" | Select-Object -ExpandProperty Value
                username = $configurationValues | Where-Object -Property Key -EQ "$wsKey/username" | Select-Object -ExpandProperty Value
                password = $configurationValues | Where-Object -Property Key -EQ "$wsKey/password" | Select-Object -ExpandProperty Value
            }
        }
        #endregion

        #region - TMS
        $tmsKey = "$ishKey/Integration/TMS"
        Write-Debug "tmsKey=$tmsKey"
        if (Test-KeyValuePS -Folder $tmsKey -FilePath $deploymentConfig) {
            Write-Verbose "TMS integration information detected"
            Write-Debug "Retrieving recursevely from $tmsKey"
            $configurationValues = Get-KeyValuePS -Key $tmsKey -Recurse -FilePath $deploymentConfig
            $hash.TMS = @{
                url       = $configurationValues | Where-Object -Property Key -EQ "$tmsKey/url" | Select-Object -ExpandProperty Value
                apiKey    = $configurationValues | Where-Object -Property Key -EQ "$tmsKey/apiKey" | Select-Object -ExpandProperty Value
                secretKey = $configurationValues | Where-Object -Property Key -EQ "$tmsKey/secretKey" | Select-Object -ExpandProperty Value
                templates = $null
            }
            $templates = @()
            $a = 1
            $templatesFound = $false
            $keys = $configurationValues | Where-Object -Property Key -like "$tmsKey/templates/template$a*" | Select-Object -ExpandProperty key
            while ($null -ne $keys) {
                $templatesFound = $true
                $keyvalues = @{}

                foreach ($key in $keys) {
                    Write-Verbose "Processing key: $key"
                    $value = $configurationValues | Where-Object -Property Key -EQ "$key" | Select-Object -ExpandProperty value
                    $shortKey = $key.Substring($key.LastIndexOf("/") + 1, $key.Length - $key.LastIndexOf("/") - 1)
                    $keyvalues += @{$shortKey = $value }
                }
                $templates += $keyvalues
                $a++
                $keys = $configurationValues | Where-Object -Property Key -like "$tmsKey/templates/template$a*" | Select-Object -ExpandProperty key
            }
            If (-not $templatesFound) { $templates = $null }
            $hash.TMS.templates = $templates
        }
        #endregion

        #region - SES
        $sesKey = "$ishKey/Integration/SES"
        Write-Debug "sesKey=$sesKey"
        if (Test-KeyValuePS -Folder $sesKey -FilePath $deploymentConfig) {
            Write-Verbose "SES integration information detected"
            Write-Debug "Retrieving recursevely from $sesKey"
            $configurationValues = Get-KeyValuePS -Key $sesKey -Recurse -FilePath $deploymentConfig
            $hash.SES = @{
                apiUrl = $configurationValues | Where-Object -Property Key -EQ "$sesKey/apiUrl" | Select-Object -ExpandProperty Value
            }
        }
        #endregion

        #region - POOLPARTY
        $ppKey = "$ishKey/Integration/POOLPARTY/Taxonomy"
        Write-Debug "ppKey=$ppKey"
        if (Test-KeyValuePS -Folder $ppKey -FilePath $deploymentConfig) {
            Write-Verbose "POOLPARTY Taxonomy integration information detected"

            $hash.POOLPARTY = @{
                Taxonomy        = $null
            }

            $configurationValues = Get-KeyValuePS -Key "$ppKey" -Recurse -FilePath $deploymentConfig

            $Sources = @()
            $Taxonomy = @{
                Sources          = $null
            }
            #Get the sources
            $a = 1
            $sourcesFound = $false
            $keys = $configurationValues | Where-Object -Property Key -like "$ppKey/sources/source$a*" | Select-Object -ExpandProperty key
            while ($null -ne $keys) {
                $sourcesFound = $true
                $keyvalues = @{}

                foreach ($key in $keys) {
                    Write-Verbose "Processing key: $key"
                    $value = $configurationValues | Where-Object -Property Key -EQ "$key" | Select-Object -ExpandProperty value
                    $shortKey = $key.Substring($key.LastIndexOf("/") + 1, $key.Length - $key.LastIndexOf("/") - 1)
                    $keyvalues += @{$shortKey = $value }
                }

                $Sources += $keyvalues

                $a++

                $keys = $configurationValues | Where-Object -Property Key -like "$ppKey/sources/source$a*" | Select-Object -ExpandProperty key
            }
            If (-not $sourcesFound) { $Sources = $null }

            $Taxonomy = @{
                Sources          = $Sources
            }

            $hash.POOLPARTY.Taxonomy = $Taxonomy
        }
        #endregion

        #region - SITES
        $sitesKey = "$ishKey/Integration/SITES"
        Write-Debug "sitesKey=$sitesKey"
        if (Test-KeyValuePS -Folder $sitesKey -FilePath $deploymentConfig) {
            Write-Verbose "SITES integration information detected"

            $hash.SITES = @{
                DynamicDelivery = $null
                Taxonomy        = $null
            }

            #region - SITES/DynamicDelivery
            $DynamicDeliveryOutputFormats = @()

            $sitesDynamicDeliveryKey = "$sitesKey/DynamicDelivery"
            $sitesDynamicDeliveryOutputFormatsKey = "$sitesKey/DynamicDelivery/outputformats"
            # Handle the case where multiple Output formats are provided
            if (Test-KeyValuePS -Folder $sitesDynamicDeliveryOutputFormatsKey -FilePath $deploymentConfig) {
                Write-Verbose "SITES DynamicDelivery integration information with multiple output formats detected"
                #Get the output formats
                $configurationValues = Get-KeyValuePS -Key $sitesDynamicDeliveryOutputFormatsKey -Recurse -FilePath $deploymentConfig

                $a = 1
                $outputFormatsFound = $false
                $keys = $configurationValues | Where-Object -Property Key -like "$sitesDynamicDeliveryOutputFormatsKey/outputformat$a*" | Select-Object -ExpandProperty key
                while ($null -ne $keys) {
                    $outputFormatsFound = $true
                    $keyvalues = @{}

                    foreach ($key in $keys) {
                        Write-Verbose "Processing key: $key"
                        $value = $configurationValues | Where-Object -Property Key -EQ "$key" | Select-Object -ExpandProperty value
                        $shortKey = $key.Substring($key.LastIndexOf("/") + 1, $key.Length - $key.LastIndexOf("/") - 1)
                        $keyvalues += @{$shortKey = $value }
                    }

                    # Should not be specified by default in AWS SSM parameter store, but let's keep the option open.
                    if (-not ($($keyvalues["DitadlvrPrefix"]))) {
                        $shortKey = "DitadlvrPrefix"
                        $value = "ish"
                        $DynamicDelivery.DitadlvrPrefix = 'ish'
                    }
                    $DynamicDeliveryOutputFormats += $keyvalues

                    $a++

                    $keys = $configurationValues | Where-Object -Property Key -like "$sitesDynamicDeliveryOutputFormatsKey/outputformat$a*" | Select-Object -ExpandProperty key
                }
            }
            elseif (Test-KeyValuePS -Folder $sitesDynamicDeliveryKey -FilePath $deploymentConfig) {
                Write-Verbose "SITES DynamicDelivery integration information detected"
                Write-Debug "Retrieving $sitesDynamicDeliveryKey subkeys"
                $configurationValues = Get-KeyValuePS -Key $sitesDynamicDeliveryKey -Recurse -FilePath $deploymentConfig
                $DynamicDelivery = @{
                    DitadlvrClientID     = $configurationValues | Where-Object -Property Key -EQ "$sitesDynamicDeliveryKey/DitadlvrClientID" | Select-Object -ExpandProperty Value
                    DitadlvrClientSecret = $configurationValues | Where-Object -Property Key -EQ "$sitesDynamicDeliveryKey/DitadlvrClientSecret" | Select-Object -ExpandProperty Value
                    DitadlvrPrefix       = $configurationValues | Where-Object -Property Key -EQ "$sitesDynamicDeliveryKey/DitadlvrPrefix" | Select-Object -ExpandProperty Value
                    DitadlvrServerURI    = $configurationValues | Where-Object -Property Key -EQ "$sitesDynamicDeliveryKey/DitadlvrServerURI" | Select-Object -ExpandProperty Value
                    DitadlvrTopologyURIs = $configurationValues | Where-Object -Property Key -EQ "$sitesDynamicDeliveryKey/DitadlvrTopologyURIs" | Select-Object -ExpandProperty Value
                    OutputFormatId       = $configurationValues | Where-Object -Property Key -EQ "$sitesDynamicDeliveryKey/OutputFormatId" | Select-Object -ExpandProperty Value
                    OutputFormatName     = $configurationValues | Where-Object -Property Key -EQ "$sitesDynamicDeliveryKey/OutputFormatName" | Select-Object -ExpandProperty Value
                }
                # Should not be specified by default in AWS SSM parameter store, but let's keep the option open.
                if (-not ($DynamicDelivery.DitadlvrPrefix)) {
                    $DynamicDelivery.DitadlvrPrefix = 'ish'
                }

                $DynamicDeliveryOutputFormats += $DynamicDelivery

                $outputFormatsFound = $true
            }

            If (-not $outputFormatsFound) { $DynamicDeliveryOutputFormats = $null }

            $hash.SITES.DynamicDelivery = $DynamicDeliveryOutputFormats
            #endregion

            #region - SITES/Taxonomy
            $sitesTaxonomyKey = "$sitesKey/Taxonomy"
            if (Test-KeyValuePS -Folder $sitesTaxonomyKey -FilePath $deploymentConfig) {
                Write-Verbose "SITES Taxonomy integration information detected"
                Write-Debug "Retrieving $sitesTaxonomyKey subkeys"
                $configurationValues = Get-KeyValuePS -Key $sitesTaxonomyKey -Recurse -FilePath $deploymentConfig

                $Sources = @()
                $Taxonomy = @{
                    Sources          = $null
                }

                #Get the sources
                $a = 1
                $sourcesFound = $false
                $keys = $configurationValues | Where-Object -Property Key -like "$sitesTaxonomyKey/sources/source$a*" | Select-Object -ExpandProperty key
                while ($null -ne $keys) {
                    $sourcesFound = $true
                    $keyvalues = @{}

                    foreach ($key in $keys) {
                        Write-Verbose "Processing key: $key"
                        $value = $configurationValues | Where-Object -Property Key -EQ "$key" | Select-Object -ExpandProperty value
                        $shortKey = $key.Substring($key.LastIndexOf("/") + 1, $key.Length - $key.LastIndexOf("/") - 1)
                        $keyvalues += @{$shortKey = $value }
                    }

                    $Sources += $keyvalues

                    $a++

                    $keys = $configurationValues | Where-Object -Property Key -like "$sitesTaxonomyKey/sources/source$a*" | Select-Object -ExpandProperty key
                }
                If (-not $sourcesFound) { $Sources = $null }

                $Taxonomy = @{
                    Sources          = $Sources
                }

                $hash.SITES.Taxonomy = $Taxonomy
                #endregion
            }
        }
        #endregion

        Write-Debug "Hash ready"

        New-Object -TypeName PSObject -Property $hash
    }

    end {

    }
}
