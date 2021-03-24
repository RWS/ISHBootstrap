<#
.Synopsis
   Wait for a URI to return a specific status
.DESCRIPTION
   Wait for a URI to return a specific status
.EXAMPLE
   Wait-UriStatus -Uri uri -Status 200 -Seconds 15
.NOTES
   Use this cmdlet to wrap the fact that Invoke-WebRequest breaks and throws too many errors.
#>
Function Wait-UriStatus {
    [OutputType([Int])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Seconds")]
        [Parameter(Mandatory = $true, ParameterSetName = "Millseconds")]
        [string]$Uri,
        [Parameter(Mandatory = $true, ParameterSetName = "Seconds")]
        [Parameter(Mandatory = $true, ParameterSetName = "Millseconds")]
        [int]$Status,
        [Parameter(Mandatory = $true, ParameterSetName = "Seconds")]
        [int]$Seconds,
        [Parameter(Mandatory = $true, ParameterSetName = "Millseconds")]
        [int]$Milliseconds
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        Write-Verbose "Waiting for $Uri to respond with status $Status."
        $startSleepSpat = @{ } + $PSBoundParameters
        $null = $startSleepSpat.Remove("Uri")
        $null = $startSleepSpat.Remove("Status")

        [int]$lastStatus = -1000

        while ($lastStatus -ne $Status) {
            Start-Sleep @startSleepSpat

            $lastStatus = Get-UriStatus -Uri $Uri

            Write-Debug "lastStatus=$lastStatus"
            if ($lastStatus -ne $Status) {
                Write-Verbose "$lastStatus is not expected $Status. Sleeping"
            }
        }

        Write-Verbose "$Uri returned expected status $Status"
    }

    end {

    }
}