<#
.Synopsis
   Get the content of the json
.DESCRIPTION
   Get the content of the json based on the requested type
.EXAMPLE
   Get-JSONContent -Type type
#>
function Get-JSONContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    begin {
        $commonJSONParameters = @{ } + $PSBoundParameters
        Write-Debug "Type=$Type"
    }

    process {
        Write-Debug "Getting JSON for Type=$Type"
        $filePath = Get-JSONContentPath @commonJSONParameters
        Write-Debug "filePath=$filePath"

        if (Test-Path $filePath) {
            Write-Verbose "Getting content from $filePath"
            Get-Content -Path $filePath -Raw | ConvertFrom-Json
        }
        else {
            Write-Verbose "$filePath doesn't exist. Returning {}"
            "{}" | ConvertFrom-Json
        }


    }

    end {

    }
}
