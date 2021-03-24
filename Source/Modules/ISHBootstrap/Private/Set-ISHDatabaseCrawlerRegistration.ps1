<#
.Synopsis
   Set a proper Crawler registration in the database
.DESCRIPTION
   Set a proper Crawler registration in the database
.EXAMPLE
   Set-ISHDatabaseCrawlerRegistration
#>
Function Set-ISHDatabaseCrawlerRegistration {
    [CmdletBinding()]
    param(

    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

    }

    process {
        <#
            The goal is to make sure there is only one valid Crawler registration in the datbase
            When there is exactly one crawler registration that is valid then no action is taken
            When not
            - then remove all registration if any
            - register the current one
        #>

        # TODO - Replace SQL Server query with method to retrieve the registered crawlers (SCTCCM-301)
        # Sql to count the number of crawler registrations
        $sqlCrawlerRegistrationCount = @"
SELECT COUNT(HOSTNAME)
FROM ISH_CRAWLER
"@
        Write-Debug "sqlCrawlerRegistrationCount=$(($sqlCrawlerRegistrationCount -split [System.Environment]::NewLine) -join ' ')"

        # Sql to count the number of valid crawler registrations
        $sqlValidCrawlerRegistrationCount = @"
SELECT COUNT(HOSTNAME)
FROM ISH_CRAWLER
WHERE HOSTNAME='InfoShare' AND CATALOG='InfoShare'
"@
        Write-Debug "sqlValidCrawlerRegistrationCount=$(($sqlValidCrawlerRegistrationCount -split [System.Environment]::NewLine) -join ' ')"

        #region TODO Invoke-SqlServerQuery@InvokeQuery
        $invokeSqlServerQuerySplat = New-SqlServerQuerySplat
        #endregion

        [int]$cralweRegistrationCount = Invoke-SqlServerQuery -Sql $sqlCrawlerRegistrationCount -NoTrans -Scalar @invokeSqlServerQuerySplat
        Write-Debug "cralweRegistrationCount=$cralweRegistrationCount"

        $validCralweRegistrationCount = Invoke-SqlServerQuery -Sql $sqlValidCrawlerRegistrationCount -NoTrans -Scalar @invokeSqlServerQuerySplat
        Write-Debug "validCralweRegistrationCount=$validCralweRegistrationCount"

        if ($cralweRegistrationCount -gt 1) {
            Write-Warning "More than 1 crawer registrations found in database"
            Invoke-ISHMaintenance -Crawler -UnRegisterAll
            Invoke-ISHMaintenance -Crawler -Register
        }
        elseif (($cralweRegistrationCount -eq 1) -and ($validCralweRegistrationCount -eq 1)) {
            Write-Verbose "Found proper crawler registrations"
        }
        elseif (($cralweRegistrationCount -eq 1) -and ($validCralweRegistrationCount -eq 0)) {
            Write-Warning "Found 1 invalid crawer registration found in database"
            Invoke-ISHMaintenance -Crawler -UnRegisterAll
            Invoke-ISHMaintenance -Crawler -Register
        }
        else {
            Write-Warning "No crawer registrations found in database"
            Invoke-ISHMaintenance -Crawler -Register
        }

    }

    end {

    }
}