<#
.Synopsis
   Remove the value from the json file
.DESCRIPTION
   Remove the value from the json file
.EXAMPLE
   Remove-JSON -Type Tag -Name name# Remove a tag
.EXAMPLE
   Remove-JSON -Type Marker -Name name # Remove a value for a marker
#>
Function Remove-JSON {
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
        Write-Debug "Getting JSON for Type=$Type"
        $filePath = Get-JSONContentPath @commonJSONParameters
        Write-Debug "filePath=$filePath"

        $json = Get-Content -Path $filePath -Raw | ConvertFrom-Json
        $json.PSObject.Properties.Remove($Name)

    }

    end {
        Set-JSONContent -JSON $json @commonJSONParameters
        Write-Verbose "Updated JSON for Type=$Type"
    }
}