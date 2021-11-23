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
    Update configuration of Admin.XMLWriteObjPluginConfig.xml based on input file.
.DESCRIPTION
    Merge input xml with Admin.XMLWriteObjPluginConfig.xml
.EXAMPLE
    Update-ISHPluginConfiguration
#>
function Update-ISHPluginConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [xml]$configXml,
        [Parameter(Mandatory = $false)]
        [string]$pluginConfig = 'Admin.XMLWriteObjPluginConfig.xml',
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
        $pluginsConfigFilePath = Resolve-Path -Path "$($enterViaUIPath.AbsolutePath)\$pluginConfig"
        Write-Debug "pluginsConfigFilePath=$($pluginsConfigFilePath)"
    }

    process {
        Write-Verbose "Updating Plugin configuration"
        if (Test-Path $pluginsConfigFilePath) {
            [xml]$pluginsConfigXml = Get-Content $pluginsConfigFilePath
            [xml]$connectorPluginsConfigXml = $configXml

            $ishCondition = $connectorPluginsConfigXml.DocumentElement.GetAttribute("ishcondition")
            if ($ishCondition -ne "") {
                $bodySequenceNodes = $pluginsConfigXml.SelectNodes("//write[@ishcondition=""$ishCondition""]/body/sequence")
            }
            else {
                $bodySequenceNodes = $pluginsConfigXml.SelectNodes("//write[not(contains(@ishcondition, 'ISHPublication'))][not(contains(@ishcondition, 'ISHAnnotation'))]/body/sequence")
            }
            $extraNodes = $connectorPluginsConfigXml.SelectNodes("//plugin")
            if ($null -ne $extraNodes) {
                foreach ($bodySequenceNode in $bodySequenceNodes) {
                    foreach ($extraNode in $extraNodes) {
                        [string]$name = $extraNode.GetAttribute("name")
                        [Xml.XmlElement]$element = $bodySequenceNode.SelectSingleNode("plugin[@name='$name']")
                        if ($null -ne $element) {
                            Write-Verbose "Remove child node."
                            $element.ParentNode.RemoveChild($element)
                        }
                        $bodySequenceNode.AppendChild($pluginsConfigXml.ImportNode($extraNode, $true))
                        $pluginConfigChanged = $true
                    }
                }
            }
            if ($pluginConfigChanged -eq $true) {
                $pluginsConfigXml.Save($pluginsConfigFilePath)
                "[$(get-content env:computername)] Added"
            }
        }
        else {
            "[FATAL ERROR] Plugin configuration could not be found ($pluginsConfigFilePath)"
        }
    }

    end {

    }
}
