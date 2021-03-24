<#
.Synopsis
    Set variable which contains path to the Deployment Configuration file
.DESCRIPTION
    Set variable which contains path to the Deployment Configuration file
.EXAMPLE
    Set-ISHDeploymentConfigurationLocation -Path 'C:\config-docs-project.json'
#>
Function Set-ISHDeploymentConfigurationLocation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        Write-Debug "New locatoion=$Path"
        if (Test-Path -Path $Path) {
            Set-Variable -Name 'ISHDeployemntConfigFile' -Value $Path
        }
        else {
            throw "Can not set '$Path' as configuration file location. Path do not exist."
        }
    }

    end {

    }
}