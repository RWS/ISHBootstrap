<#
.Synopsis
   Upgrade the database
.DESCRIPTION
   Invokes the DBUpgradeTool.exe if the DatabaseUpgrade component is configured on the system
.EXAMPLE
   Update-ISHDB
#>
Function Update-ISHDB {
    [CmdletBinding()]
    param(
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        if (Test-ISHComponent -Name DatabaseUpgrade) {
            Invoke-ISHDBUpgradeTool -Upgrade
        }
        else {
            Write-Warning "Skipping. DatabaseUpgrade component not found"
        }
    }

    end {

    }
}