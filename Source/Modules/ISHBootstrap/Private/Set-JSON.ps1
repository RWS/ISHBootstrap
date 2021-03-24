<#
.Synopsis
   Set the values in the json file
.DESCRIPTION
   Set the values in the json file
.EXAMPLE
   Set-JSON -Type Tag -Name name -Value value # Set the tag
.EXAMPLE
   Set-JSON -Type Marker -Name name -Value value # Set the value for the marker
#>
Function Set-JSON {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        $Value = $null,
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $commonJSONParameters = @{ } + $PSBoundParameters
        $null = $commonJSONParameters.Remove("Name")
        $null = $commonJSONParameters.Remove("Value")
    }

    process {
        Write-Debug "Updating JSON for Type=$Type"
        $json = Get-JSONContent @commonJSONParameters
        if ($json | Get-Member -Name $Name) {
            $json.$Name = $Value
            Write-Verbose "Updated item with Name=$Name"
        }
        else {
            $json | Add-Member -MemberType NoteProperty -Name $Name -Value $Value
            Write-Verbose "Added item with Name=$Name"
        }
    }

    end {
        Set-JSONContent -JSON $json @commonJSONParameters
        Write-Verbose "Updated JSON for Type=$Type"
    }
}