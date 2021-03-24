<#
.Synopsis
   Get the specific path from the deployment
.DESCRIPTION
   Get the specific path from the deployment
.EXAMPLE
   Get-ISHDeploymentPath -EnterViaUI
   Get-ISHDeploymentPath -JettyIPAccess
#>
function Get-ISHDeploymentPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "EnterViaUI")]
        [switch]$EnterViaUI,
        [Parameter(Mandatory = $true, ParameterSetName = "JettyIPAccess")]
        [switch]$JettyIPAccess
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {

        Write-Debug "Loading information from the deployment"
        $deployment = Get-ISHDeployment

        switch ($PSCmdlet.ParameterSetName) {
            'EnterViaUI' {
                $relativePath = "Author\EnterViaUI"
                $absolutePath = Join-Path -Path $deployment.WebPath -ChildPath $relativePath
            }
            'JettyIPAccess' {
                $relativePath = "Utilities\SolrLucene\Jetty\etc\jetty-ipaccess.xml"
                $absolutePath = Join-Path -Path $deployment.AppPath -ChildPath $relativePath
            }
        }
        Write-Debug "relativePath=$relativePath"
        Write-Debug "path=$absolutePath"

        [PSCustomObject]@{
            AbsolutePath = $absolutePath
            RelativePath = $relativePath
        }
    }

    end {

    }
}
