<#
.Synopsis
   Get the tag or multiple tags
.DESCRIPTION
   Get the tag or multiple tags
.EXAMPLE
   Get-Tag
.EXAMPLE
   Get-Tag -Name name
#>
function Get-Tag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name = $null
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $useEC2Tag = (Test-RunOnEC2) -and (-not (Test-JSONContent -Type LocalTag))
        Write-Debug "useEC2Tag=$useEC2Tag"

        if ($useEC2Tag) {
            $tags = Get-TagEC2
        }
        else {
            $tags = Get-JSON -Type LocalTag
        }

        if ($Name) {
            $tags | Where-Object -Property Name -EQ $Name | Select-Object -ExpandProperty Value
        }
        else {
            $tags
        }
    }

    end {

    }
}
