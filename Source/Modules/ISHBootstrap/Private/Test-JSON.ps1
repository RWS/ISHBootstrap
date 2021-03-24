<#
.Synopsis
   Test the values in the json file
.DESCRIPTION
   Test the values in the json file
.EXAMPLE
   Test-JSON -Type Tag -Name name # Test a tag
.EXAMPLE
   Test-JSON -Type Marker -Name name # Test a marker
#>
Function Test-JSON {
    [OutputType([Boolean])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $commonJSONParameters = @{ } + $PSBoundParameters
        $null = $commonJSONParameters.Remove("Name")
    }

    process {
        $json = Get-JSONContent @commonJSONParameters
        if ($json | Get-Member -Name $Name) {
            $true
        }
        else {
            $false
        }
    }

    end {

    }
}