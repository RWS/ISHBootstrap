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
    )

    begin {
        $projectStageKey = Get-Key -ProjectStage
        $ishKey = Get-Key -ISH
        Write-Debug "projectStageKey=$projectStageKey"
        Write-Debug "ishKey=$ishKey"
        $deploymentConfig = (Get-Variable -Name "ISHDeployemntConfigFile").Value
        Write-Debug "deploymentConfig=$deploymentConfig"
    }

    process {
        $hash = @{
            XOPUS = $null
            FONTO = $null
            SITES = $null
        }

        #region - XOPUS
        $xopusKey = "$ishKey/Integration/XOPUS"
        Write-Debug "xopusKey=$xopusKey"
        if (Test-KeyValuePS -Folder $xopusKey -FilePath $deploymentConfig) {
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
                $collectiveSpacsDraftSpace = Test-KeyValuePS -Key "$fontoKey/DraftSpace" -FilePath $deploymentConfig
            }
            else {
                $collectiveSpacsDraftSpace = $true
            }

            $collectiveSpacesReviewSpace = Test-KeyValuePS -Key "$fontoKey/ReviewSpace" -FilePath $deploymentConfig

            $hash.FONTO = @{
                CollectiveSpacesDocumentHistoryForDraftSpace = $collectiveSpacesDocumentHistoryForDraftSpace
                CollectiveSpacesDraftSpace                   = $collectiveSpacsDraftSpace
                CollectiveSpacesReviewSpace                  = $collectiveSpacesReviewSpace
            }
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
                    $keyvalues = @{ }

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

                $Metadatabindings = @()
                $Sources = @()
                $Taxonomy = @{
                    Metadatabindings = $null
                    Sources          = $null
                }

                #Get the metadatabindings
                $a = 1
                $metadatabindingsFound = $false
                $keys = $configurationValues | Where-Object -Property Key -like "$sitesTaxonomyKey/metadatabindings/metadatabinding$a*" | Select-Object -ExpandProperty key
                while ($null -ne $keys) {
                    $metadatabindingsFound = $true
                    $keyvalues = @{ }

                    foreach ($key in $keys) {
                        Write-Verbose "Processing key: $key"
                        $value = $configurationValues | Where-Object -Property Key -EQ "$key" | Select-Object -ExpandProperty value
                        $shortKey = $key.Substring($key.LastIndexOf("/") + 1, $key.Length - $key.LastIndexOf("/") - 1)
                        $keyvalues += @{$shortKey = $value }
                    }

                    $Metadatabindings += $keyvalues

                    $a++

                    $keys = $configurationValues | Where-Object -Property Key -like "$sitesTaxonomyKey/metadatabindings/metadatabinding$a*" | Select-Object -ExpandProperty key
                }
                If (-not $metadatabindingsFound) { $Metadatabindings = $null }

                #Get the sources
                $a = 1
                $sourcesFound = $false
                $keys = $configurationValues | Where-Object -Property Key -like "$sitesTaxonomyKey/sources/source$a*" | Select-Object -ExpandProperty key
                while ($null -ne $keys) {
                    $sourcesFound = $true
                    $keyvalues = @{ }

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
                    Metadatabindings = $Metadatabindings
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
