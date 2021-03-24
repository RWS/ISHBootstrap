<#
.Synopsis
   Set the marker on the system
.DESCRIPTION
   Set the marker (key/value) on the system.
   This marker can later be used in the Recipe (Get-Marker/Test-Marker) to drive specific customizations and/or configuration changes.
.EXAMPLE
   Set-Marker -Name name
.EXAMPLE
   Set-Marker -Name name -Value value
#>
Function Set-Marker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        $Value = $null
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        Set-JSON @PSBoundParameters -Type Marker
    }

    end {

    }
}