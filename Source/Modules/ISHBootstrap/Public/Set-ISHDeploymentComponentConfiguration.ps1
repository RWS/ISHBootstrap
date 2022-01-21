<#
# Copyright (c) 2021 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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
    Configure the components for selected project/stage
.DESCRIPTION
    This cmdlet adds congifuration for crawler, background task and translation components.
.PARAMETER ConfigFilePath
    Path to json configuration file.
.PARAMETER ISHBootstrapVersion
    Version of ISHBootstrap module.
.PARAMETER Project
    A project name. Indicates how this configuration will be referenced in a recipe.
.PARAMETER Stage
    Stage of a project. (e.g. Dev, Test, Prod, etc.)
    Similar to project will be used as a part of configuration reference in recipe.
.EXAMPLE
    Set-ISHDeploymentComponentConfiguration -ConfigFilePath configfilepath -ISHBootstrapVersion 2.0 -Project project -Stage stage
#>
Function Set-ISHDeploymentComponentConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [string]$ConfigFilePath,
        [Parameter(Mandatory = $true)]
        [string]$ISHBootstrapVersion,
        [Parameter(Mandatory = $true)]
        [string]$Project,
        [Parameter(Mandatory = $true, HelpMessage = "The Tridion Docs stage (environment), e.g. Development, Acceptance, Production")]
        [string]$Stage
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $keyValues = Get-Content -Raw -Path $ConfigFilePath | ConvertFrom-Json
        Write-Verbose "Reed $ConfigFilePath"
        if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage ) {
            throw "Project/Stage $Project/$Stage does not exist. Use New-Project.ps1"
        }

        $componentsKV = [pscustomobject]@{
            "BackgroundTask-Single"  = @{Count = 1 }
            "BackgroundTask-Multi"   = @{Count = 1 }
            Crawler                  = @{Count = 1 }
            TranslationBuilder       = @{Count = 1 }
            TranslationOrganizer     = @{Count = 1 }
        }

        if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component) {
            $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH | Add-Member -MemberType NoteProperty -Name Component -Value $componentsKV
        }
        else {
            $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component = $componentsKV
        }

        ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFilePath
        Write-Verbose "Updated $ConfigFilePath"
    }

    end {

    }
}
