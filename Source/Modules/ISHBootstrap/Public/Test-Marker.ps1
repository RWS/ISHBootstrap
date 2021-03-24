<#
.Synopsis
   Test if the marker is avaialble on the system
.DESCRIPTION
   Test if the marker is avaialble on the system.
   This can be used in the Recipe to drive specific customizations and/or configuration changes.
.EXAMPLE
   Test-Marker -Name name
#>
Function Test-Marker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        Test-JSON @PSBoundParameters -Type Marker
    }

    end {

    }
}