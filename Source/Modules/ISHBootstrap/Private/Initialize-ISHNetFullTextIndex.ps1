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
   Makes required changes for FullTextIndex to be accessible
.DESCRIPTION
   Makes required changes for FullTextIndex to be accessible
   - Open windows firewall for 8078
   - Modify Jetty .\App\Utilities\SolrLucene\Jetty\etc\jetty-ipaccess.xml
.EXAMPLE
   Initialize-ISHNetFullTextIndex
#>
Function Initialize-ISHNetFullTextIndex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        Write-Debug "Node has not been once initialized from AMI"
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
        if (Test-ISHRequirement -Marker -Name "ISH.InitializedNetFullTextIndex" @ISHDeploymentSplat) {
            throw "Node is already initialized ISH FullTextIndex Network Connectivity"
        }
    }

    process {
        #region Adapt Jetty IPAccess configuration

        $jettyIPAccessPath = Get-ISHDeploymentPath -JettyIPAccess @ISHDeploymentSplat
        $SolrInCmdPath = Get-ISHDeploymentPath -SolrInCmd @ISHDeploymentSplat

        if (Test-Path $jettyIPAccessPath.AbsolutePath) {
            Write-Debug "jettyIPAccessPath.AbsolutePath=$($jettyIPAccessPath.AbsolutePath)"
            Write-Debug "jettyIPAccessPath.RelativePath=$($jettyIPAccessPath.RelativePath)"
            $filePath = $jettyIPAccessPath.AbsolutePath
            Write-Debug "filePath=$filePath"
            Backup-ISHDeployment -Path $jettyIPAccessPath.RelativePath -App @ISHDeploymentSplat

            [xml]$xml = Get-Content -Path $filePath -Raw
            # <Item>172.0-255.0-255.0-255</Item>

            $xpathArrayWhiteList = 'Configure[@id="Server"]/Set[@name="handler"]/New[@id="IPAccessHandler"]/Set[@name="white"]/Array'
            $xpathArrayWhiteListJetty93Up = 'Configure[@id="Server"]/Call[@name="insertHandler"]/Arg/New[@id="IPAccessHandler"]/Set[@name="white"]/Array'
            Write-Debug "xpathArrayWhiteList=$xpathArrayWhiteList"

            $nodeArrayWhiteList = $xml.SelectSingleNode($xpathArrayWhiteList)
            if (-not $nodeArrayWhiteList) {
                Write-Debug "xpathArrayWhiteListJetty93Up=$xpathArrayWhiteListJetty93Up"
                $nodeArrayWhiteList = $xml.SelectSingleNode($xpathArrayWhiteListJetty93Up)
            }
            $commentExplanation = $xml.CreateComment("Automation changes: Allow incomming connections from all ip ranges");
            $nodeItem = $xml.CreateElement("Item")
            $null = $nodeItem.InsertAfter($xml.CreateTextNode("0-255.0-255.0-255.0-255"), $null)
            $null = $nodeArrayWhiteList.InsertAfter($nodeItem, $null)
            $null = $nodeArrayWhiteList.InsertAfter($commentExplanation, $null)

            $xml.Save($filePath)
        }
        if (Test-Path $SolrInCmdPath.AbsolutePath) {
            Write-Debug "SolrInCmdPath.AbsolutePath=$($SolrInCmdPath.AbsolutePath)"
            Write-Debug "SolrInCmdPath.RelativePath=$($SolrInCmdPath.RelativePath)"
            Backup-ISHDeployment -Path $SolrInCmdPath.RelativePath -App @ISHDeploymentSplat
            $fileContent = Get-Content -Path $SolrInCmdPath.AbsolutePath -Raw
			$fileContent += @"
set SOLR_OPTS=%SOLR_OPTS% -Dsolr.dns.prevent.reverse.lookup=true
set SOLR_JETTY_HOST=0.0.0.0
set SOLR_IP_ALLOWLIST=0.0.0.0/0, 127.0.0.1, 127.0.0.2
"@
            Set-Content -Path $SolrInCmdPath.AbsolutePath -Value $fileContent
            $filePath = $SolrInCmdPath.AbsolutePath
        }
        Write-Verbose "$filePath adapted to allow incomming connection from all ips"

        #endregion

        #region Open Windows Firewall

        New-NetFirewallRule -DisplayName "ISH-FullTextIndex" -Direction Inbound -Action Allow -LocalPort @("8078") -Protocol TCP | Out-Null

        #endregion

        Write-Debug "Setting marker ISH.InitializedNetFullTextIndex, to avoid re-execution on the same host"
        Set-ISHMarker -Name "ISH.InitializedNetFullTextIndex" @ISHDeploymentSplat
    }

    end {

    }
}
