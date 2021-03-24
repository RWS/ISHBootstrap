<#
.Synopsis
   Get one or multiple markers from the system
.DESCRIPTION
   Get one or multiple markers from the system.
   This (these) marker value(s) can be used in the Recipe to drive specific customizations and/or configuration changes.
.EXAMPLE
   Get-Marker
.EXAMPLE
   Get-Marker -Name name
#>
Function Get-Marker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Name = $null
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        Get-JSON @PSBoundParameters -Type Marker
    }

    end {

    }
}