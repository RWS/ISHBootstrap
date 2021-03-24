<#
.Synopsis
   Invoke Crawler's reindex flow if it hasn't done before
.DESCRIPTION
   Invoke Crawler's reindex flow if it hasn't done before
.EXAMPLE
   Invoke-ISHCrawlerReIndex
#>
Function Invoke-ISHCrawlerReIndex {
    [CmdletBinding()]
    param(
    )

    begin {
    }

    process {
        <#
            The goal is to align the Crawler's index with the database store
            Since we don't know anything about the database's origin, we will issue a reindex when the stack is created.
            If consecutive executions happen from the same host, then the reindex will happen only the first time.
            If the host dies unexpectedly, when replaced by a new instance, although unnecessary the reindex will be triggered because there no information.
        #>

        Write-Debug "Testing if the reindex has happened already once."

        if (-not (Test-Requirement -Marker -Name "ISH.EC2InvokedCrawlerReindex")) {
            # Reindex has never been invoked by this host
            Invoke-ISHMaintenance -Crawler -ReIndex

            #region TODO Invoke-ISHMaintenance-Reindex
            # Although Invoke-ISHMaintenance -Crawler -ReIndex never raised an error, because of SCTCM-307 it really didn't reindex.
            # For this reason we execute the actual executable correctly
            $deployment = Get-ISHDeployment

            $crawlerFolder = Join-Path -Path $deployment.AppPath -ChildPath Crawler\Bin
            Write-Debug "crawlerFolder=$crawlerFolder"

            $crawlerPath = Join-Path -Path $crawlerFolder Crawler.exe
            Write-Debug "crawlerPath=$crawlerPath"

            $crawlerArgs = @(
                "--reindex"
                "ISHAll"
            )

            & $crawlerPath $crawlerArgs 2>&1
            Write-Debug "LASTEXITCODE=$LASTEXITCODE"

            #endregion
            Write-Verbose "Issued a fulltextindex reindex"

            Write-Debug "Setting marker ISH.EC2InvokedCrawlerReindex, to avoid re-execution on the same host"
            Set-Marker -Name "ISH.EC2InvokedCrawlerReindex"
        }
        else {
            Write-Debug "Reindex has already happened once from this host. No taking any action"
        }
    }

    end {

    }
}