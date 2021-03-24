<#
.Synopsis
   Invokes the ishbootstrap sequence
.DESCRIPTION
   Initiates the ishbootstrap flow
.EXAMPLE
   Invoke-ISHDeploymentSequence -RootPath rootpath
#>
Function Invoke-ISHDeploymentSequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $newBoundParameters = @{ } + $PSBoundParameters
    }

    process {
        Write-Debug $env:PSModulePath
        Invoke-ISHDeploymentStep -ApplicationStop @newBoundParameters

        Invoke-ISHDeploymentStep -BeforeInstall @newBoundParameters

        Invoke-ISHDeploymentStep -AfterInstall @newBoundParameters

        Invoke-ISHDeploymentStep -ApplicationStart @newBoundParameters

        Invoke-ISHDeploymentStep -ValidateService @newBoundParameters
    }

    end {

    }
}