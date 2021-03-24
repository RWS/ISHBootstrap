<#
.Synopsis
   Set the content of the json
.DESCRIPTION
   Set the content of the json based on the requested type
.EXAMPLE
   Set-JSONContent -JSON $json -Type Tag
.EXAMPLE
   Set-JSONContent -JSON $json -Type Marker
#>
function Set-JSONContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$JSON,
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $commonJSONParameters = @{ } + $PSBoundParameters
        $null = $commonJSONParameters.Remove("JSON")
    }

    process {
        Write-Debug "Getting JSON for Type=$Type"
        $filePath = Get-JSONContentPath @commonJSONParameters
        Write-Debug "filePath=$filePath"

        if (-not (Test-Path -Path $filePath)) {
            $null = New-Item -Path $filePath -ItemType File -Force
            Write-Verbose "Created $filePath"
        }
        $JSON | ConvertTo-Json | Format-Json | Out-File -FilePath $filePath -Force
        Write-Verbose "Updated $filePath"
    }

    end {

    }
}
