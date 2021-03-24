<#
.Synopsis
   Get the dependency to FullTextIndex component
.DESCRIPTION
   Get the dependency to FullTextIndex component (Local, ExternalEC2, None)
.EXAMPLE
   Get-ISHFullTextIndexExternalDependency
#>
Function Get-ISHFullTextIndexExternalDependency {
    [CmdletBinding()]
    [OutputType([String])]
    param(

    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        # Check if the host is on EC2. When on EC2 check if the FullTextIndex component is also enabled
        # When the the host is on EC2 and the FullTextIndex component is disabled, the dependency is ExternalEC2
        # When the the host is on EC2 and the FullTextIndex component is enabled, the dependency is Local
        # When the the host is not on EC2 and the FullTextIndex component is disabled, the dependency is None
        # When the the host is not on EC2 and the FullTextIndex component is enabled, the dependency is Local
        $isHostedOnEC2 = Test-RunOnEC2
        Write-Debug "isHostedOnEC2=$isHostedOnEC2"
        $isFullTextIndexEnabled = Test-ISHComponent -Name FullTextIndex
        Write-Debug "isFullTextIndexEnabled=$isFullTextIndexEnabled"

        if ($isHostedOnEC2 -and $isFullTextIndexEnabled) {
            $dependency = "Local"
        }
        elseif ($isHostedOnEC2 -and (-not ($isFullTextIndexEnabled))) {
            $dependency = "ExternalEC2"
        }
        elseif ((-not $isHostedOnEC2) -and $isFullTextIndexEnabled) {
            $dependency = "Local"
        }
        else {
            $dependency = "None"
        }

        Write-Debug "dependency=$dependency"
        Write-Verbose "FullTextIndex dependency is $dependency"
        $dependency
    }

    end {

    }
}