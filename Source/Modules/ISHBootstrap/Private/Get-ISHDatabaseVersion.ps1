<#
.Synopsis
   Get the current version of the database
.DESCRIPTION
   Get the current version of the database
.EXAMPLE
   Get-ISHDatabaseVersion
#>
Function Get-ISHDatabaseVersion {
    [CmdletBinding()]
    param(

    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

    }

    # TODO - Replace SQL Server query with DBUT SaveInfoShareVersionHistoryXML (SCTCCM-300)
    process {
        $sql = @"
SELECT Top 1 [VERSION]
FROM [dbo].[ISH_SETUP_HISTORY]
WHERE STATUS = 'Completed' AND ACTION = 'DatabaseUpgrade'
ORDER BY CREATIONDATE DESC
"@

        #region TODO Invoke-SqlServerQuery@InvokeQuery
        $invokeSqlServerQuerySplat = New-SqlServerQuerySplat
        #endregion

        $ishDBVersion = Invoke-SqlServerQuery -Sql $sql -NoTrans -Scalar @invokeSqlServerQuerySplat
        Write-Debug "ishDBVersion=$ishDBVersion"
        $ishDBVersion
    }

    end {

    }
}