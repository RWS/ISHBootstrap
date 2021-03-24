<#
.Synopsis
   Sets the centralized configuration on the database
.DESCRIPTION
   Using ISHRemote to:
   Upload the EnterViaUI xml files,
   Create/update output formats (depending on the configured integrations)
.EXAMPLE
   Update-ISHDBConfiguration
#>
function Update-ISHDBConfiguration {
    [OutputType([String])]
    [CmdletBinding()]
    param(
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        # The EnterViaUI xml files,
        $enterViaUIPath = Get-ISHDeploymentPath -EnterViaUI
        Write-Debug "enterViaUIPath.AbsolutePath=$($enterViaUIPath.AbsolutePath)"

        <# To get a list with ISHRemote
        $typeDefinition=Get-IshTypeFieldDefinition -IshSession $session |Where-Object -Property ISHType -EQ ISHConfiguration
        $typeDefinition|Ft Name,Description -Wrap
        #>
        # Create a known mapping between filenames and field name in ISHConfiguration
        $fileNameFieldNameMap = @{
            "Admin.XMLBackgroundTaskConfiguration.xml"   = "FISHBACKGROUNDTASKCONFIG"
            "Admin.XMLChangeTrackerConfig.xml"           = "FISHCHANGETRACKERCONFIG"
            "Admin.XMLCollectiveSpacesConfiguration.xml" = "FISHCOLLECTIVESPACESCFG"
            "Admin.XMLExtensionConfiguration.xml"        = "FISHEXTENSIONCONFIG"
            "Admin.XMLInboxConfiguration.xml"            = "FINBOXCONFIGURATION"
            "Admin.XMLPublishPluginConfiguration.xml"    = "FISHPUBLISHPLUGINCONFIG"
            "Admin.XMLStatusConfiguration.xml"           = "FSTATECONFIGURATION"
            "Admin.XMLTranslationConfiguration.xml"      = "FTRANSLATIONCONFIGURATION"
            "Admin.XMLWriteObjPluginConfig.xml"          = "FISHWRITEOBJPLUGINCFG"
        }
        foreach ($fnfn in $fileNameFieldNameMap.GetEnumerator()) { Write-Debug "$($fnfn.Key)=$($fnfn.Value)" }

    }

    process {
        try {
            # Create new ishremote session
            Write-Debug "Creating ISHRemote remote session"
            $session = New-ISHWSSession -ServiceAdmin
            Write-Verbose "ISHRemote remote session created"


            # Get the configuration (including the configuration for the Output Format for SITES/DitaDelivery
            $ISHData = Get-ISHIntegrationConfiguration


            # Create/Update the Output Format VOUTPUTFORMATDITADELIVERY with the specified values when SITES/DitaDelivery is configured
            if ($ISHData.SITES) {
                if ($ISHData.SITES.DynamicDelivery) {
                    Write-Verbose "SITES DynamicDelivery integration detected"
                    # Loop through configured output formats
                    foreach ($hash in $ISHData.SITES.DynamicDelivery) {
                        $dynamicDeliveryOutputFormatId = $($hash["OutputFormatId"])
                        $dynamicDeliveryDitadlvrServerURI = $($hash["DitadlvrServerURI"])
                        $dynamicDeliveryDitadlvrClientID = $($hash["DitadlvrClientID"])
                        $dynamicDeliveryDitadlvrClientSecret = $($hash["DitadlvrClientSecret"])
                        $dynamicDeliveryDitadlvrPrefix = $($hash["DitadlvrPrefix"])
                        $dynamicDeliveryDitadlvrTopologyURIs = $($hash["DitadlvrTopologyURIs"])
                        $dynamicDeliveryOutputFormatName = $($hash["OutputFormatName"])


                        Write-Verbose "Checking if OutputFormat with id = '$dynamicDeliveryOutputFormatId' already exists ..."

                        # Find all OutputFormats
                        $ishOutputFormats = Find-IshOutputFormat -IshSession $session -ActivityFilter "None"

                        # Find OutputFormat with id $dynamicDeliveryOutputFormatId
                        $outputFormatDitaDelivery = $ishOutputFormats | Where-Object { $_.fishoutputformatname_none_element -eq $dynamicDeliveryOutputFormatId }

                        if ($null -eq $outputFormatDitaDelivery.IshRef) {
                            Write-Verbose "Creating OutputFormat with Name = '$dynamicDeliveryOutputFormatName'..."
                            $ishMetadata = Set-IshMetadataField -IshSession $session -Name "FISHRESOLUTIONS" -Level "none" -Value "Low"  `
                            | Set-IshMetadataField -IshSession $session -Name "FISHRESOLUTIONSTOEXPORT" -Level "none" -Value "VRESOLUTIONSTOEXPORTALLRESOLUTIONS" -ValueType Element `
                            | Set-IshMetadataField -IshSession $session -Name "FSTYLEPROCESSOR" -Level "none" -Value "DITA-OT\InfoShare" `
                            | Set-IshMetadataField -IshSession $session -Name "FDITAOTTRANSTYPE" -Level "none" -Value "ishditadelivery" `
                            | Set-IshMetadataField -IshSession $session -Name "FISHOBJECTACTIVE" -Level "none" -Value "TRUE" -ValueType Element `
                            | Set-IshMetadataField -IshSession $session -Name "FISHPUBRESOLVEVARIABLES" -Level "none" -Value "TRUE" -ValueType Element `
                            | Set-IshMetadataField -IshSession $session -Name "FISHCLEANUP" -Level "none" -Value "TRUE" -ValueType Element `
                            | Set-IshMetadataField -IshSession $session -Name "FISHINCLUDEMISSINGOBJS" -Level "none" -Value "FALSE" -ValueType Element `
                            | Set-IshMetadataField -IshSession $session -Name "FISHDITADLVRSERVERURI" -Level "none" -Value $dynamicDeliveryDitadlvrServerURI `
                            | Set-IshMetadataField -IshSession $session -Name "FISHDITADLVRCLIENTID" -Level "none" -Value $dynamicDeliveryDitadlvrClientID `
                            | Set-IshMetadataField -IshSession $session -Name "FISHDITADLVRCLIENTSECRET" -Level "none" -Value $dynamicDeliveryDitadlvrClientSecret `
                            | Set-IshMetadataField -IshSession $session -Name "FISHDITADLVRIDPREFIX" -Level "none" -Value $dynamicDeliveryDitadlvrPrefix `
                            | Set-IshMetadataField -IshSession $session -Name "FISHDITADLVRTOPOLOGYURIS" -Level "none" -Value $dynamicDeliveryDitadlvrTopologyURIs

                            $createdOutputFormat = Add-IshOutputFormat -IshSession $session `
                                -Name "$dynamicDeliveryOutputFormatName" `
                                -EDT "EDTZIP" `
                                -Metadata $ishMetadata

                            $id = $createdOutputFormat.IshRef
                            Write-Verbose "Created Output with id: $id"
                        }
                        else {
                            Write-Verbose "Updating OutputFormat with Name = '$outputFormatDitaDelivery.IshRef' ..."
                            $ishMetadata = Set-IshMetadataField -IshSession $session -Name "FDITAOTTRANSTYPE" -Level "none" -Value "ishditadelivery" `
                            | Set-IshMetadataField -IshSession $session -Name "FISHPUBRESOLVEVARIABLES" -Level "none" -Value "TRUE" -ValueType Element `
                            | Set-IshMetadataField -IshSession $session -Name "FISHINCLUDEMISSINGOBJS" -Level "none" -Value "FALSE" -ValueType Element `
                            | Set-IshMetadataField -IshSession $session -Name "FISHOUTPUTFORMATNAME" -Level "none" -Value $dynamicDeliveryOutputFormatName `
                            | Set-IshMetadataField -IshSession $session -Name "FISHDITADLVRSERVERURI" -Level "none" -Value $dynamicDeliveryDitadlvrServerURI `
                            | Set-IshMetadataField -IshSession $session -Name "FISHDITADLVRCLIENTID" -Level "none" -Value $dynamicDeliveryDitadlvrClientID `
                            | Set-IshMetadataField -IshSession $session -Name "FISHDITADLVRCLIENTSECRET" -Level "none" -Value $dynamicDeliveryDitadlvrClientSecret `
                            | Set-IshMetadataField -IshSession $session -Name "FISHDITADLVRIDPREFIX" -Level "none" -Value $dynamicDeliveryDitadlvrPrefix `
                            | Set-IshMetadataField -IshSession $session -Name "FISHDITADLVRTOPOLOGYURIS" -Level "none" -Value $dynamicDeliveryDitadlvrTopologyURIs

                            $updatedOutputFormat = Set-IshOutputFormat -IshSession $session `
                                -Id $outputFormatDitaDelivery.IshRef `
                                -Edt "EDTZIP" `
                                -Metadata $ishMetadata

                            $id = $updatedOutputFormat.IshRef
                            Write-Verbose "Updated Output with id: $id"
                        }
                    }
                }
                else {
                    Write-Verbose "SITES DynamicDelivery integration not detected"
                }

                if ($ISHData.SITES.Taxonomy) {
                    Write-Verbose "SITES Taxonomy integration detected"
                    # CONFIGURE EXTENSION FOR 'TridionSitesTaxonomyConnector

                    # infoShareExtensionConfig
                    #    - Add <metadatabindings> if not exists
                    #    - Add <metadatabinding> for every entry in $hash.SITES.Taxonomy.Metadatabindings
                    #    - Add <sources> if not exists
                    #    - Add <source> for every entry in $hash.SITES.Taxonomy.Sources
                    $extensionConfigFilePath = $enterViaUIPath.AbsolutePath + "\Admin.XMLExtensionConfiguration.xml"
                    [xml]$extensionConfigXml = Get-Content $extensionConfigFilePath

                    if ($ISHData.SITES.Taxonomy.Metadatabindings -and $ISHData.SITES.Taxonomy.Sources) {
                        $connectorExtensionConfigString = "<metadatabindingandsourceelementstoadd>"
                        $connectorExtensionConfigString += "<metadatabindings>"
                        foreach ($hash in $ISHData.SITES.Taxonomy.Metadatabindings) {
                            $connectorExtensionConfigString += "<metadatabinding ishfieldname=""$($hash["ishfieldname"])"" sourceref=""$($hash["sourceref"])"" />"
                        }
                        $connectorExtensionConfigString += "</metadatabindings>"

                        $connectorExtensionConfigString += "<sources>"
                        foreach ($hash in $ISHData.SITES.Taxonomy.Sources) {
                            $source = "
    <source id=""$($hash["id"])"" handler=""$($hash["handler"])"">
      <initialize>
        <parameters>
          <parameter name=""CategoryId"">$($hash["CategoryId"])</parameter>
          <parameter name=""CacheExpiryTimeout"">$($hash["CacheExpiryTimeout"])</parameter>
          <parameter name=""EndpointAddress"">$($hash["EndpointAddress"])</parameter>
          <parameter name=""Username"">$($hash["Username"])</parameter>
          <parameter name=""Password"">$($hash["Password"])</parameter>
          <parameter name=""ClientCredentialType"">$($hash["ClientCredentialType"])</parameter>
        </parameters>
      </initialize>
    </source>"
                            $connectorExtensionConfigString += $source
                        }
                        $connectorExtensionConfigString += "</sources></metadatabindingandsourceelementstoadd>"

                        [xml]$connectorExtensionConfigXml = $connectorExtensionConfigString

                        $metadataBindingsNodes = $extensionConfigXml.SelectNodes("//metadatabindings")
                        $extraNodes = $connectorExtensionConfigXml.SelectNodes("//metadatabinding")
                        if ($extraNodes.Count -gt 0 -and $metadataBindingsNodes.Count -eq 0) {
                            $metadataBindingsNode = $extensionConfigXml.CreateElement("metadatabindings")

                            $firstNode = $extensionConfigXml.DocumentElement.FirstChild
                            if ($null -eq $firstNode) {
                                $temp = $extensionConfigXml.DocumentElement.AppendChild($metadataBindingsNode)
                            }
                            else {
                                $temp = $extensionConfigXml.DocumentElement.InsertBefore($metadataBindingsNode, $firstNode)
                            }

                            foreach ($extraNode in $extraNodes) {
                                $temp = $metadataBindingsNode.AppendChild($extensionConfigXml.ImportNode($extraNode, $true))
                                $extensionConfigChanged = $true
                            }
                        }
                        else {
                            $metadataBindingsNode = $metadataBindingsNodes.Item(0)
                            foreach ($extraNode in $extraNodes) {
                                [string]$name = $extraNode.GetAttribute("ishfieldname")
                                [Xml.XmlElement]$element = $metadataBindingsNode.SelectSingleNode("metadatabinding[@ishfieldname='$name']")
                                if ($null -ne $element) {
                                    Write-Verbose "Remove child node."
                                    $element.ParentNode.RemoveChild($element)
                                }
                                $temp = $metadataBindingsNode.AppendChild($extensionConfigXml.ImportNode($extraNode, $true))
                                $extensionConfigChanged = $true
                            }
                        }

                        $sourcesNodes = $extensionConfigXml.SelectNodes("//sources")
                        $extraNodes = $connectorExtensionConfigXml.SelectNodes("//source")
                        if ($extraNodes.Count -gt 0 -and $sourcesNodes.Count -eq 0) {
                            $sourcesNode = $extensionConfigXml.CreateElement("sources")
                            $extensionConfigXml.DocumentElement.InsertAfter($sourcesNode, $metadataBindingsNode)
                            foreach ($extraNode in $extraNodes) {
                                $temp = $sourcesNode.AppendChild($extensionConfigXml.ImportNode($extraNode, $true))
                                $extensionConfigChanged = $true
                            }
                        }
                        else {
                            $sourcesNode = $sourcesNodes.Item(0)
                            foreach ($extraNode in $extraNodes) {
                                [string]$name = $extraNode.GetAttribute("id")
                                [Xml.XmlElement]$element = $sourcesNode.SelectSingleNode("source[@id='$name']")
                                if ($null -ne $element) {
                                    Write-Verbose "Remove child node."
                                    $element.ParentNode.RemoveChild($element)
                                }
                                $temp = $sourcesNode.AppendChild($extensionConfigXml.ImportNode($extraNode, $true))
                                $extensionConfigChanged = $true
                            }
                        }
                        if ($extensionConfigChanged -eq $true) {
                            $extensionConfigXml.Save($extensionConfigFilePath)
                            "[$(get-content env:computername)] Added"
                        }
                    }


                    # infoSharePluginConfig
                    #    - Add/Enable CONFIGURE EXTENSION FOR 'TridionSitesTaxonomyConnector' for every entry in $hash.SITES.Taxonomy.Metadatabindings/ishfieldname
                    $pluginsConfigFilePath = $enterViaUIPath.AbsolutePath + "\Admin.XMLWriteObjPluginConfig.xml"
                    $connectorUpdatePluginsConfigFilePath = Resolve-Path -Path "$PSScriptRoot\..\EnterViaUI\TridionSitesTaxonomyConnector.UpdatePluginConfig.ps1"
                    & $connectorUpdatePluginsConfigFilePath $($enterViaUIPath.AbsolutePath + "\")
                }
                else {
                    Write-Verbose "SITES Taxonomy integration not detected"
                }
            }
            else {
                Write-Verbose "SITES integration not detected"
            }

            # Process each xml file inside enterviaui folder
            # TODO XMLAdminOrder Should there be a order in the files?
            Get-ChildItem -Path $enterViaUIPath.AbsolutePath -Filter "*.xml" | ForEach-Object {
                $fileName = $_.Name
                $filePath = $_.FullName

                Write-Debug "fileName=$fileName"
                Write-Debug "filePath=$filePath"


                # Check if the filename has a known field mapping
                if ($fileNameFieldNameMap.ContainsKey($fileName)) {
                    $fieldName = $fileNameFieldNameMap[$fileName]
                    Write-Debug "fieldName=$fieldName"
                    $xmlFromDatabase = Get-IshSetting -FieldName $fieldName -IshSession $session
                    $xmlFromFile = Get-Content -Path $filePath -Raw

                    Write-Debug "Comparing xml in database with local file system"
                    if ($xmlFromDatabase -ne $xmlFromFile) {
                        Write-Debug "XML in file is different than in database"
                        Write-Debug "Uploading $filePath into configuration with field name $fieldName"
                        $null = Set-IshSetting -IshSession $session -FieldName $fieldName -Value $xmlFromFile
                        Write-Verbose "Uploaded $filePath into configuration with field name $fieldName"
                    }
                    else {
                        Write-Verbose "Content of $filePath is identical to content of configuration field $fieldName"
                    }
                }
                else {
                    Write-Warning "Cannot map filename $fileName to field. Skipping"
                }
            }
        }
        finally {
            if ($session) {
                Write-Debug "Disposing session"
                try {
                    $session.Dispose()
                }
                catch {
                    Write-Debug $_.Exception
                }
            }
        }
    }

    end {

    }
}
