<#
.Synopsis
   Start the ish deployment
.DESCRIPTION
   Start the ish deployment
.EXAMPLE
   Start-ISH
#>
Function Start-ISH {
    [CmdletBinding()]
    param(

    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {

        Start-ISHDeployment

    }

    end {

    }
}