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
    Update configuration of Admin.XMLExtensionConfiguration.xml based on input file.
.DESCRIPTION
    Merge input xml with Admin.XMLExtensionConfiguration.xml
.EXAMPLE
    Update-ISHExtensionConfiguration
#>
function Update-ISHExtensionConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [xml]$configXml,
        [Parameter(Mandatory = $false)]
        [string]$extensionConfig = 'Admin.XMLExtensionConfiguration.xml',
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
        # The EnterViaUI xml files,
        $enterViaUIPath = Get-ISHDeploymentPath -EnterViaUI @ISHDeploymentSplat
        $extensionsConfigFilePath = Resolve-Path -Path "$($enterViaUIPath.AbsolutePath)\$extensionConfig"
        Write-Debug "pluginsConfigFilePath=$($extensionsConfigFilePath)"
    }

    process {
        Write-Verbose "Updating Extensions configuration"
        $extensionConfigChanged = $false
        "[$(get-content env:computername)] Adding 'Metadata Binding' in $extensionsConfigFilePath"

        if (Test-Path $extensionsConfigFilePath) {
            [xml]$extensionConfigXml = Get-Content $extensionsConfigFilePath
            [xml]$connectorExtensionConfigXml = $configXml
        
            $metadataBindingsNodes = $extensionConfigXml.SelectNodes("//metadatabindings")
            $extraNodes = $connectorExtensionConfigXml.SelectNodes("//metadatabinding")
            if ($extraNodes.Count -gt 0 -and $metadataBindingsNodes.Count -eq 0) {
                $metadataBindingsNode = $extensionConfigXml.CreateElement("metadatabindings")
        
                $firstNode = $extensionConfigXml.DocumentElement.FirstChild
                $temp
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
                    $name = $extraNode.GetAttribute("ishfieldname")
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
                    $name = $extraNode.GetAttribute("id")
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
                $extensionConfigXml.Save($extensionsConfigFilePath)
                "[$(get-content env:computername)] Added"
            }
        } 
        else {
            "[FATAL ERROR] Extension configuration could not be found ($extensionsConfigFilePath)"
        }
    }

    end {

    }
}
