<#
# Copyright (c) 2021 All Rights Reserved by the SDL Group.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#>

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
