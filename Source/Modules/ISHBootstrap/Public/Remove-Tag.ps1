<#
.Synopsis
   Remove existing tag
.DESCRIPTION
   Remove existing tag
.EXAMPLE
   Remove-Tag -Name name
#>
function Remove-Tag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $useEC2Tag = (Test-RunOnEC2) -and (-not (Test-JSONContent -Type LocalTag))
        Write-Debug "useEC2Tag=$useEC2Tag"

        if ($useEC2Tag) {
            Remove-TagEC2 @PSBoundParameters
        }
        else {
            Remove-JSON @PSBoundParameters -Type LocalTag
        }
    }

    end {

    }
}
