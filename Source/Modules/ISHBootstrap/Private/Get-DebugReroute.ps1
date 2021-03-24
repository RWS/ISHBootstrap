<#
.Synopsis
   Get the key
.DESCRIPTION
   Get the key
.EXAMPLE
   Get-DebugReroute -ProjectStage
#>
function Get-DebugReroute {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Project")]
        [switch]$ProjectStage,
        [Parameter(Mandatory = $true, ParameterSetName = "ISH")]
        [switch]$ISH,
        [Parameter(Mandatory = $true, ParameterSetName = "Custom")]
        [switch]$Custom
    )

    begin {
        $debugKey = Get-Key -DebugReroute
        Write-Debug "debugKey=$debugKey"
        $deploymentConfig = (Get-Variable -Name "ISHDeployemntConfigFile").Value
        Write-Debug "deploymentConfig=$deploymentConfig"
    }

    process {
        Write-Verbose "Testing if $debug key exists"
        if (Test-KeyValuePS -Folder $debugKey -FilePath $deploymentConfig) {
            Write-Debug "$debug key found. Getting value"
            $debugValues = Get-KeyValuePS -Key $debugKey -Recurse -FilePath $deploymentConfig

            $rerouteKey = $PSCmdlet.ParameterSetName
            Write-Debug "$rerouteKey=$rerouteKey"
            if (($rerouteKey -eq 'ISH') -or ($rerouteKey -eq 'Custom')) {
                $rerouteKey = "Project"
            }
            Write-Debug "$rerouteKey=$rerouteKey"

            Write-Verbose "Retrieving key $debugKey/Reroute/$rerouteKey"
            $debugValues | Where-Object -Property Key -EQ "$debugKey/Reroute/$rerouteKey" | Select-Object -ExpandProperty Value
        }
        else {
            Write-Debug "$debug key not found"
            $null
        }
    }

    end {

    }
}
