<#
.Synopsis
   Test if the json file exists
.DESCRIPTION
   Test if the json file exists based on the requested type
.EXAMPLE
   Test-JSONContent -Type Tag
.EXAMPLE
   Test-JSONContent -Type Marker
#>function Test-JSONContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $commonJSONParameters = @{ } + $PSBoundParameters
    }

    process {
        Write-Debug "Getting JSON for Type=$Type"
        $filePath = Get-JSONContentPath @commonJSONParameters
        Write-Debug "filePath=$filePath"

        Test-Path -Path $filePath
    }

    end {

    }
}
