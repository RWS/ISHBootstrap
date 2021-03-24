<#
.Synopsis
   Apply the integration configuration from AWS SSM parameter store into the deployment
.DESCRIPTION
   Apply the integration configuration from AWS SSM parameter store into the deployment
   WorldServer, TMS, XOPUS
.EXAMPLE
   Set-ISHIntegrationConfiguration
#>
function Set-ISHIntegrationConfiguration {
    [CmdletBinding()]
    param(
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        function EnableIshFrmField([System.Xml.XmlDocument]$metadataConfigXml, [string]$name) {
            [bool]$configChanged = $false

            $node = $metadataConfigXml.SelectSingleNode("//ishfrmfield[@name='" + $name + "']")
            if ($null -eq $node) {
                foreach ($commentNode in $metadataConfigXml.SelectNodes("//comment()[contains(. , 'name=""" + $name + """')]")) {
                    $commentText = $commentNode.Value
                    $posStart = $commentNode.Value.IndexOf("<ishfrmfield ")
                    $posEnd = $commentNode.Value.IndexOf("</ishfrmfield>", $posStart) + 14
                    $text = $commentNode.Value.Substring($posStart, $posEnd - $posStart)

                    $newNode = New-Object System.Xml.XmlDocument
                    $newNode.PreserveWhitespace = $true
                    $newNode.LoadXml($text)

                    $temp = $commentNode.ParentNode.ReplaceChild($metadataConfigXml.ImportNode($newNode.DocumentElement, $true), $commentNode)

                    $configChanged = $true
                }
            }

            foreach ($commentNode in $metadataConfigXml.SelectNodes("//comment()[contains(. , 'ref=""" + $name + """')]")) {
                $commentText = $commentNode.Value
                $posStart = $commentNode.Value.IndexOf("<ishfrmfield ref=""" + $name + """")
                $posEnd = $commentNode.Value.IndexOf("/>", $posStart) + 2
                $text = $commentNode.Value.Substring($posStart, $posEnd - $posStart)

                $newNode = New-Object System.Xml.XmlDocument
                $newNode.PreserveWhitespace = $true
                $newNode.LoadXml($text)

                $temp = $commentNode.ParentNode.ReplaceChild($metadataConfigXml.ImportNode($newNode.DocumentElement, $true), $commentNode)

                $configChanged = $true
            }

            return $configChanged
        }
    }

    process {
        $ISHData = Get-ISHIntegrationConfiguration

        if ($ISHData.XOPUS) {
            $domain = $ISHData.XOPUS.Domain
            Write-Debug "domain=$domain"
            Enable-ISHUIContentEditor
            Set-ISHContentEditor -Domain $domain -LicenseKey $ISHData.XOPUS.LicenseKey
            Write-Verbose "Applied XOPUS integration"
        }
        else {
            Write-Verbose "XOPUS integration not detected"
        }

        if ($ISHData.FONTO) {
            $collectiveSpacesDraftSpace = $ISHData.FONTO.CollectiveSpacesDraftSpace
            Write-Debug "collectiveSpacesDraftSpace=$collectiveSpacesDraftSpace"
            if ($collectiveSpacesDraftSpace) {
                Enable-ISHUICollectiveSpaces -DraftSpace
                Write-Verbose "Enabled FONTO integration - CollectiveSpaces - DraftSpace"
            }

            $collectiveSpacesDocumentHistoryForDraftSpace = $ISHData.FONTO.CollectiveSpacesDocumentHistoryForDraftSpace
            Write-Debug "collectiveSpacesDocumentHistoryForDraftSpace=$collectiveSpacesDocumentHistoryForDraftSpace"
            if ($collectiveSpacesDocumentHistoryForDraftSpace) {
                Enable-ISHUICollectiveSpaces -DocumentHistoryForDraftSpace
                Write-Verbose "Enabled FONTO integration - CollectiveSpaces - DocumentHistoryForDraftSpace"
            }

            $collectiveSpacesReviewSpace = $ISHData.FONTO.CollectiveSpacesReviewSpace
            Write-Debug "collectiveSpacesReviewSpace=$collectiveSpacesReviewSpace"
            if ($collectiveSpacesReviewSpace) {
                Enable-ISHUICollectiveSpaces -ReviewSpace
                Write-Verbose "Enabled FONTO integration - CollectiveSpaces - ReviewSpace"
            }

            Write-Verbose "Applied FONTO integration"
        }
        else {
            Write-Verbose "FONTO integration not detected"
        }

        # Update metadataconfig.xml when SITES/DitaDelivery and/or SITES/Taxonomy is configured
        if ($ISHData.SITES) {
            if ($ISHData.SITES.DynamicDelivery) {
                Write-Verbose "SITES DynamicDelivery integration detected"
                # Loop through configured output formats
                $dynamicDeliveryOutputFormatNames = $null
                foreach ($hash in $ISHData.SITES.DynamicDelivery) {
                    $dynamicDeliveryOutputFormatName = $($hash["OutputFormatName"])
                    Write-Verbose "Adding the OutputFormat with name = '$dynamicDeliveryOutputFormatName' to be added to the SDLDITADeliveryOptionsGroup ishcondition ..."
                    $dynamicDeliveryOutputFormatNames += ", '$dynamicDeliveryOutputFormatName'"
                }

                if ($null -ne $dynamicDeliveryOutputFormatNames) {
                    # metadataconfig
                    #    - Add the new output format to the ishcondition of SDLDITADeliveryOptionsGroup ishfrmgroup
                    Write-Verbose "Updating the SDLDITADeliveryOptionsGroup ishcondition with name = '$dynamicDeliveryOutputFormatNames'..."
                    $projectSuffix = Get-ISHDeploymentParameters -Name projectsuffix -ValueOnly
                    $webFolderPathWithSuffix = $(Get-ISHDeploymentParameters -Name webpath -ValueOnly) + "\Web" + $projectSuffix
                    $metadataConfigFilePath = $webFolderPathWithSuffix + "\Author\ASP\ClientConfig\MetadataConfig.xml"
                    (Get-Content $metadataConfigFilePath).Replace("OutputFormat in ('Dynamic Delivery')", "OutputFormat in ('Dynamic Delivery'$dynamicDeliveryOutputFormatNames)") | Set-Content $metadataConfigFilePath
                }
            }
            else {
                Write-Verbose "SITES DynamicDelivery integration not detected"
            }

            if ($ISHData.SITES.Taxonomy) {
                Write-Verbose "SITES Taxonomy integration detected"
                # metadataconfig
                #    - Add/Enable CONFIGURE EXTENSION FOR 'TridionSitesTaxonomyConnector' for every entry in $hash.SITES.Taxonomy.Metadatabindings/ishfieldname
                $projectSuffix = Get-ISHDeploymentParameters -Name projectsuffix -ValueOnly
                $webFolderPathWithSuffix = $(Get-ISHDeploymentParameters -Name webpath -ValueOnly) + "\Web" + $projectSuffix
                $metadataConfigFilePath = $webFolderPathWithSuffix + "\Author\ASP\ClientConfig\MetadataConfig.xml"

                Write-Verbose "Uncomment 'TridionSitesTaxonomyConnector' fields in $metadataConfigFilePath start"

                if (Test-Path $metadataConfigFilePath) {
                    [System.Xml.XmlDocument]$metadataConfigXml = New-Object System.Xml.XmlDocument
                    $metadataConfigXml.PreserveWhitespace = $true
                    $metadataConfigXml.Load($metadataConfigFilePath)

                    $releaseNameAdded = EnableIshFrmField -metadataConfigXml $metadataConfigXml -name "PublicationMBProductReleaseNameField"
                    $familyNameAdded = EnableIshFrmField -metadataConfigXml $metadataConfigXml -name "PublicationMBProductFamilyNameField"
                    $contentTypeAdded = EnableIshFrmField -metadataConfigXml $metadataConfigXml -name "ContentReferenceTypeField"


                    if ($releaseNameAdded -or $familyNameAdded -or $contentTypeAdded) {
                        $settings = New-Object System.Xml.XmlWriterSettings;
                        $settings.OmitXmlDeclaration = $false;

                        $writer = [System.Xml.XmlWriter]::Create($metadataConfigFilePath)
                        $metadataConfigXml.Save( $writer )
                        $writer.Close()

                        Write-Verbose "'TridionSitesTaxonomyConnector' fields enabled"
                    }
                }
                else {
                    Write-Verbose "[FATAL ERROR] Metadata configuration could not be found ($metadataConfigFilePath)"
                }
            }
            else {
                Write-Verbose "SITES Taxonomy integration not detected"
            }
        }
        else {
            Write-Verbose "SITES integration not detected"
        }

    }

    end {

    }
}