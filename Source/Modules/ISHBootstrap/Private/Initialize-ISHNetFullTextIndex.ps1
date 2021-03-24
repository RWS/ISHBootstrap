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
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        if (Test-Requirement -Marker -Name "ISH.InitializedNetFullTextIndex") {
            throw "Node is already initialized ISH FullTextIndex Network Connectivity"
        }
        Write-Debug "Node has not been once initialized from AMI"
    }

    process {
        #region Adapt Jetty IPAccess configuration

        $jettyIPAccessPath = Get-ISHDeploymentPath -JettyIPAccess
        Write-Debug "jettyIPAccessPath.AbsolutePath=$($jettyIPAccessPath.AbsolutePath)"
        Write-Debug "jettyIPAccessPath.RelativePath=$($jettyIPAccessPath.RelativePath)"
        $filePath = $jettyIPAccessPath.AbsolutePath
        Write-Debug "filePath=$filePath"
        Backup-ISHDeployment -Path $jettyIPAccessPath.RelativePath -App

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
        Write-Verbose "$filePath adapted to allow incomming connection from all ips"

        #endregion

        #region Open Windows Firewall

        New-NetFirewallRule -DisplayName "ISH-FullTextIndex" -Direction Inbound -Action Allow -LocalPort @("8078") -Protocol TCP | Out-Null

        #endregion

        Write-Debug "Setting marker ISH.InitializedNetFullTextIndex, to avoid re-execution on the same host"
        Set-Marker -Name "ISH.InitializedNetFullTextIndex"
    }

    end {

    }
}
