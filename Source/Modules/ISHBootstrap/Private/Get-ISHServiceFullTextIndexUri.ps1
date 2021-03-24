<#
.Synopsis
   Get the information about the Full Text Index Uri
.DESCRIPTION
   Get the information about the Full Text Index Uri
.EXAMPLE
   Get-ISHIntegrationFullTextIndexUri
#>
Function Get-ISHServiceFullTextIndexUri {
    [CmdletBinding()]
    param(

    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

    }

    process {
        $dependency = Get-ISHFullTextIndexExternalDependency
        Write-Debug "dependency=$dependency"
        switch ($dependency) {
            'ExternalEC2' {
                $hostname = Get-ISHDeployment | Select-Object -ExpandProperty AccessHostName
                $project = Get-Tag -Name "Project"
                $stage = Get-Tag -Name "Stage"

                $fullTextIndexUri = "http://backendsingle.ish.internal.$($project)-$($stage).$($hostname):8078/solr/"

            }
            'Local' {
                $fullTextIndexUri = "http://127.0.0.1:8078/solr/"

            }
            'None' {
                $fullTextIndexUri = "http://127.0.0.1:8078/solr/"
            }
        }

        Write-Debug "fullTextIndexUri=$fullTextIndexUri"
        Write-Verbose "For FullTextIndex dependency $dependency the uri is $fullTextIndexUri"

        $fullTextIndexUri
    }

    end {

    }
}