<#
.Synopsis
   Test if the system is configured with the tag
.DESCRIPTION
   Test if the system is configured with the tag
.EXAMPLE
   Test-Tag -Name name
#>
Function Test-Tag {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $tags = Get-Tag
        if ($tags | Where-Object -Property Name -EQ $Name) {
            $true
        }
        else {
            $false
        }
    }

    end {
    }
}