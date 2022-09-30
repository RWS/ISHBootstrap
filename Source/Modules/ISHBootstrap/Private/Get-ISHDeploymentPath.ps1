<#
# Copyright (c) 2022 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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
        [switch]$JettyIPAccess,
        [Parameter(Mandatory = $true, ParameterSetName = "SolrInCmd")]
        [switch]$SolrInCmd,
        [Parameter(Mandatory = $false,ParameterSetName = "JettyIPAccess")]
        [Parameter(Mandatory = $false,ParameterSetName = "SolrInCmd")]
        [Parameter(Mandatory = $false,ParameterSetName = "EnterViaUI")]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $ISHDeploymentNameSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentNameSplat = @{Name = $ISHDeployment}
        }
    }

    process {

        Write-Debug "Loading information from the deployment"
        $deployment = Get-ISHDeployment @ISHDeploymentNameSplat

        switch ($PSCmdlet.ParameterSetName) {
            'EnterViaUI' {
                $relativePath = "Author\EnterViaUI"
                $absolutePath = Join-Path -Path $deployment.WebPath -ChildPath $relativePath
            }
            'JettyIPAccess' {
                $relativePath = "Utilities\SolrLucene\Jetty\etc\jetty-ipaccess.xml"
                $absolutePath = Join-Path -Path $deployment.AppPath -ChildPath $relativePath
            }
            'SolrInCmd' {
                $relativePath = "Utilities\SolrLucene\bin\solr.in.cmd"
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
