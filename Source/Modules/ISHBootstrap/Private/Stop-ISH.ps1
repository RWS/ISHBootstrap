<#
.Synopsis
   Stop the ish deployment
.DESCRIPTION
   Stop the ish deployment
.EXAMPLE
   Stop-ISH
#>
Function Stop-ISH {
    [CmdletBinding()]
    param(

    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {

        Stop-ISHDeployment
    }

    end {

    }
}