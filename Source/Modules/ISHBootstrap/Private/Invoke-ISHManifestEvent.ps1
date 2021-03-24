<#
.Synopsis
   Invokes the script configured on an event from a manifest
.DESCRIPTION
   Invokes the script configured on an event from a manifest
.EXAMPLE
   Invoke-ISHManifestEvent -ManifestHash $manifestHash -EventName StopBeforeCore
#>
Function Invoke-ISHManifestEvent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$ManifestHash,
        [Parameter(Mandatory = $true)]
        [ValidateSet("PreRequisite", "StopBeforeCore", "StopAfterCore", "Execute", "DatabaseUpgradeBeforeCore", "DatabaseUpgradeAfterCore", "DatabaseUpdateBeforeCore", "DatabaseUpdateAfterCore", "StartBeforeCore", "StartAfterCore", "Validate")]
        [string]$EventName
    )

    begin {
        Write-Debug "EventName=$EventName"

    }

    process {
        if ($ManifestHash) {
            $path = $ManifestHash."$($EventName)Path"
            Write-Verbose "ManifestType:$($ManifestHash.Type) Event:$EventName Script:$path"
            if ($path) {
                Write-Debug "Invoking $path"
                $output = & $path
                Write-Verbose "Invoked $path"

                if ($output) {
                    Write-Warning "Script $path wrote unexpected output to the pipeline"
                    Write-Debug $output
                }
            }
        }
        else {
            Write-Debug "Manifest hash is empty"
        }
    }

    end {

    }
}