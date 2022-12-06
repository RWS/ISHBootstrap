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
    Remove Deployment configuration (project/stage) custom values
.DESCRIPTION
    Removes selected custom configuration key from deployment configuration project.
.PARAMETER ConfigFilePath
    Path to json configuration file from which configuration key will be removed.
.PARAMETER ISHBootstrapVersion
    Version of ISHBootstrap module that specified in configuration.
.PARAMETER Project
    A project name where deployment configuration is located.
.PARAMETER Stage
    Name of a stage with custom key for removal.
.PARAMETER Key
    Name of a key which needs to be removed.
.EXAMPLE
    Remove-ISHDeploymentCustomConfiguration -ConfigFilePath configfilepath -ISHBootstrapVersion 2.0 -Project project -Stage stage -Key custom/key
#>
Function Remove-ISHDeploymentCustomConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Root")]
        [Parameter(Mandatory = $true, ParameterSetName = "Key")]
        [ValidateScript( { Test-Path $_ })]
        [string]$ConfigFilePath,
        [Parameter(Mandatory = $true, ParameterSetName = "Root")]
        [Parameter(Mandatory = $true, ParameterSetName = "Key")]
        [string]$ISHBootstrapVersion,
        [Parameter(Mandatory = $true, ParameterSetName = "Root")]
        [Parameter(Mandatory = $true, ParameterSetName = "Key")]
        [string]$Project,
        [Parameter(Mandatory = $true, HelpMessage = "The Tridion Docs stage (environment), e.g. Development, Acceptance, Production", ParameterSetName = "Root")]
        [Parameter(Mandatory = $true, HelpMessage = "The Tridion Docs stage (environment), e.g. Development, Acceptance, Production", ParameterSetName = "Key")]
        [string]$Stage,
        [Parameter(Mandatory = $true, ParameterSetName = "Key")]
        [string]$Key
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $keyValues = Get-Content -Raw -Path $ConfigFilePath | ConvertFrom-Json
        Write-Verbose "Reed existing $ConfigFilePath"
        if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage) {
            Write-Verbose "Project/Stage $Project/$Stage does not exist."
        }
        else {
            switch ($PSCmdlet.ParameterSetName) {
                'Root' {
                    $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.PSObject.Properties.Remove('Custom')
                }
                'Key' {
                    $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Custom.PSObject.Properties.Remove($Key)
                }
            }
        }
        ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFilePath
        Write-Verbose "Updated $ConfigFilePath"
    }

    end {

    }
}
