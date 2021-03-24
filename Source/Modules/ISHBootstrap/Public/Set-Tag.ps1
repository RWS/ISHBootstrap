<#
.Synopsis
   Configures locally the system with the tag
.DESCRIPTION
   When not hosted on EC2 use this cmdlet to mimic a tag
.EXAMPLE
   Set-Tag -Name name
.EXAMPLE
   Set-Tag -Name name -Value value
#>
Function Set-Tag {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $false)]
        [string]$Value = $null
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        # TODO: Review. Has a big impact on performance (%CPU and time)
        #$useEC2Tag = (Test-RunOnEC2) -and (-not (Test-JSONContent -Type LocalTag))
        $useEC2Tag = $false
        Write-Debug "useEC2Tag=$useEC2Tag"

        if ($useEC2Tag) {
            Set-TagEC2 @PSBoundParameters
        }
        else {
            Set-JSON @PSBoundParameters -Type LocalTag
        }
    }

    end {

    }
}