<#
.Synopsis
   Invokes the ishbootstrap sequence for the deployment step/hook
.DESCRIPTION
   Initiates the ishbootstrap flow that match the specific deployment step/hook
.EXAMPLE
   Invoke-ISHDeploymentStep -ApplicationStop -RootPath rootpath
.EXAMPLE
   Invoke-ISHDeploymentStep -BeforeInstall -RootPath rootpath
.EXAMPLE
   Invoke-ISHDeploymentStep -AfterInstall -RootPath rootpath
.EXAMPLE
   Invoke-ISHDeploymentStep -ApplicationStart -RootPath rootpath
.EXAMPLE
   Invoke-ISHDeploymentStep -ValidateService -RootPath rootpath
#>
Function Invoke-ISHDeploymentStep {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "ApplicationStop")]
        [switch]$ApplicationStop,
        [Parameter(Mandatory = $true, ParameterSetName = "BeforeInstall")]
        [switch]$BeforeInstall,
        [Parameter(Mandatory = $true, ParameterSetName = "AfterInstall")]
        [switch]$AfterInstall,
        [Parameter(Mandatory = $true, ParameterSetName = "ApplicationStart")]
        [switch]$ApplicationStart,
        [Parameter(Mandatory = $true, ParameterSetName = "ValidateService")]
        [switch]$ValidateService,
        [Parameter(Mandatory = $true, ParameterSetName = "ApplicationStop")]
        [Parameter(Mandatory = $true, ParameterSetName = "BeforeInstall")]
        [Parameter(Mandatory = $true, ParameterSetName = "AfterInstall")]
        [Parameter(Mandatory = $true, ParameterSetName = "ApplicationStart")]
        [Parameter(Mandatory = $true, ParameterSetName = "ValidateService")]
        [string]$RootPath
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $newBoundParameters = @{ } + $PSBoundParameters
    }

    process {
        Invoke-ISHCodeDeployHook @newBoundParameters
    }

    end {

    }
}
