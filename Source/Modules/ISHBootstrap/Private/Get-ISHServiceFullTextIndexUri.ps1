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
   Get the information about the Full Text Index Uri
.DESCRIPTION
   Get the information about the Full Text Index Uri
.EXAMPLE
   Get-ISHIntegrationFullTextIndexUri
#>
Function Get-ISHServiceFullTextIndexUri {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
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
        $dependency = Get-ISHFullTextIndexExternalDependency @ISHDeploymentNameSplat
        Write-Debug "dependency=$dependency"
        $deployment = Get-ISHDeployment  @ISHDeploymentNameSplat
        if ($deployment.SoftwareVersion.Major -ge 15) {
            $protocol = 'https'
        }
        else {
            $protocol = 'http'
        }
        switch ($dependency) {
            'ExternalEC2' {
                $hostname = $deployment | Select-Object -ExpandProperty AccessHostName
                $project = Get-ISHTag -Name "Project" @ISHDeploymentNameSplat
                $stage = Get-ISHTag -Name "Stage" @ISHDeploymentNameSplat

                $fullTextIndexUri = "$($protocol)://backendsingle.ish.internal.$($project)-$($stage).$($hostname):8078/solr/"

            }
            'Local' {
                $fullTextIndexUri = "$($protocol)://127.0.0.1:8078/solr/"

            }
            'None' {
                $fullTextIndexUri = "$($protocol)://127.0.0.1:8078/solr/"
            }
        }

        Write-Debug "fullTextIndexUri=$fullTextIndexUri"
        Write-Verbose "For FullTextIndex dependency $dependency the uri is $fullTextIndexUri"

        $fullTextIndexUri
    }

    end {

    }
}
