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
   Initiates the bakery's flow for Content Manager that match a specific code deploy hook
.DESCRIPTION
   Initiates the bakery's flow for Content Manager that match a specific code deploy hook
.EXAMPLE
   Invoke-ISHCodeDeployHook -ApplicationStop -RecipeFolderPath recipefolderpath
.EXAMPLE
   Invoke-ISHCodeDeployHook -BeforeInstall -RecipeFolderPath recipefolderpath
.EXAMPLE
   Invoke-ISHCodeDeployHook -AfterInstall -RecipeFolderPath recipefolderpath
.EXAMPLE
   Invoke-ISHCodeDeployHook -ApplicationStart -RecipeFolderPath recipefolderpath
.EXAMPLE
   Invoke-ISHCodeDeployHook -ValidateService -RecipeFolderPath recipefolderpath
#>
Function Invoke-ISHCodeDeployHook {
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
        [string]$RecipeFolderPath,
        [Parameter(Mandatory = $false, ParameterSetName = "ApplicationStop")]
        [Parameter(Mandatory = $false, ParameterSetName = "BeforeInstall")]
        [Parameter(Mandatory = $false, ParameterSetName = "AfterInstall")]
        [Parameter(Mandatory = $false, ParameterSetName = "ApplicationStart")]
        [Parameter(Mandatory = $false, ParameterSetName = "ValidateService")]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        Write-Debug "RecipeFolderPath=$RecipeFolderPath"
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }

    }

    process {
        $manifests = Get-ChildItem -Path $RecipeFolderPath -Filter "manifest.psd1" -Depth 1 | Where-Object {
            Write-Debug "Testing if $($_.FullName) is valid manifest"
            Test-Manifest -Path $_.FullName
        } | ForEach-Object {
            Write-Debug "Reading manifest from $($_.FullName)"
            Read-Manifest -Path $_.FullName
        }

        Write-Debug "Filtering for recipes from manifests.count=$($manifests.Count)"
        $recipeManifest = $manifests | Where-Object -Property Type -EQ "ISHRecipe"
        if ($recipeManifest.Count -gt 1) {
            Write-Debug "Found $($recipeManifest.Count)"
            throw "Only one recipe allowed in $RecipeFolderPath"
        }
        if ($recipeManifest) {
            Write-Debug "Validating recipe $($recipeManifest.FilePath)"

            $recipePublishMetadata = $recipeManifest.Publish
            Write-Debug "recipePublishMetadata.Name=$($recipePublishMetadata.Name)"
            Write-Debug "recipePublishMetadata.Version=$($recipePublishMetadata.Version)"
            Write-Debug "recipePublishMetadata.Date=$($recipePublishMetadata.Date)"
            Write-Debug "recipePublishMetadata.Engine=$($recipePublishMetadata.Engine)"

            Set-Item -Path ENV:\ISHBootstrap_Recipe_Type -Value ISHRecipe
            Set-Item -Path ENV:\ISHBootstrap_Recipe_Name -Value $recipePublishMetadata.Name
            Set-Item -Path ENV:\ISHBootstrap_Recipe_Version -Value $recipePublishMetadata.Version

            $major = $recipeManifest.PrerequisiteMajor
            if ($major) {
                $minor = $recipeManifest.PrerequisiteMinor
                $build = $recipeManifest.PrerequisiteBuild
                $revision = $recipeManifest.PrerequisiteRevision
                Write-Debug "Validating recipes prerequisite version [$major,$minor,$build,$revision] against deployment version"
                if (-not (Test-ISHRequirement -ISH -Major $major -Minor $minor -Build $build -Revision $revision @ISHDeploymentSplat)) {
                    throw "Product version (major,minor,build,revision)=($major,$minor,$build,$revision) in recipe's manifest prerequisite version is not met"
                }
            }
        }
        Invoke-ISHManifestEvent -ManifestHash $recipeManifest -EventName "PreRequisite" @ISHDeploymentSplat

        switch ($PSCmdlet.ParameterSetName) {
            'ApplicationStop' {
                Write-Verbose "Starting ApplicationStop"

                Write-Verbose "Executing recipe's StopBeforeCore"
                Invoke-ISHManifestEvent -ManifestHash $recipeManifest -EventName "StopBeforeCore" @ISHDeploymentSplat

                Write-Verbose "Executing core's Stop-ISHDeployment"
                Stop-ISH @ISHDeploymentSplat

                Write-Verbose "Executing recipe's StopAfterCore"
                Invoke-ISHManifestEvent -ManifestHash $recipeManifest -EventName "StopAfterCore" @ISHDeploymentSplat

                Write-Verbose "Finished ApplicationStop"
            }
            'BeforeInstall' {
                Write-Verbose "Starting BeforeInstall"
                Write-Verbose "Finished BeforeInstall"

            }
            'AfterInstall' {
                Write-Verbose "Starting AfterInstall"

                Write-Verbose "Executing core's Set-ISHCoreConfiguration"
                Set-ISHCoreConfiguration @ISHDeploymentSplat

                Write-Verbose "Executing core's Set-ISHIntegrationConfiguration"
                Set-ISHIntegrationConfiguration @ISHDeploymentSplat

                Write-Verbose "Executing core's Update-ISHAdminBackgroundTaskFile"
                Update-ISHAdminBackgroundTaskFile @ISHDeploymentSplat

                Write-Verbose "Executing recipe's Execute"
                Invoke-ISHManifestEvent -ManifestHash $recipeManifest -EventName "Execute" @ISHDeploymentSplat

                # Block for Database upgrade
                if (Test-ISHComponent -Name DatabaseUpgrade @ISHDeploymentSplat) {
                    #region Database Upgrade
                    Write-Verbose "Executing recipe's DatabaseUpgradeBeforeCore"
                    Invoke-ISHManifestEvent -ManifestHash $recipeManifest -EventName "DatabaseUpgradeBeforeCore" @ISHDeploymentSplat

                    Write-Verbose "Executing core's Update-ISHDB"
                    Update-ISHDB @ISHDeploymentSplat

                    Write-Verbose "Executing recipe's DatabaseUpgradeAfterCore"
                    Invoke-ISHManifestEvent -ManifestHash $recipeManifest -EventName "DatabaseUpgradeAfterCore" @ISHDeploymentSplat

                    #endregion

                    #region Database update
                    try {
                        Write-Verbose "Starting ISHCM Web application pools"
                        Start-ISHWeb @ISHDeploymentSplat

                        Write-Verbose "Waiting for ISHCM Web application pools"
                        Wait-ISHWeb @ISHDeploymentSplat

                        Write-Verbose "Executing recipe's DatabaseUpdateBeforeCore"
                        Invoke-ISHManifestEvent -ManifestHash $recipeManifest -EventName "DatabaseUpdateBeforeCore" @ISHDeploymentSplat

                        Write-Verbose "Executing core's Update-ISHDBConfiguration"
                        Update-ISHDBConfiguration @ISHDeploymentSplat

                        Write-Verbose "Executing recipe's DatabaseUpdateAfterCore"
                        Invoke-ISHManifestEvent -ManifestHash $recipeManifest -EventName "DatabaseUpdateAfterCore" @ISHDeploymentSplat
                    }
                    finally {
                        Write-Verbose "Stopping ISHCM Web application pools"
                        Stop-ISHWeb @ISHDeploymentSplat
                    }

                    #endregion
                }

                # Handle the Crawler registrations and Reindex if necessary
                if (Test-ISHComponent -Name DatabaseUpgrade @ISHDeploymentSplat) {
                    Write-Verbose "Making sure there is one Crawler registration in the database"
                    Set-ISHDatabaseCrawlerRegistration @ISHDeploymentSplat
                }
                if (Test-ISHComponent -Name FullTextIndex @ISHDeploymentSplat) {
                    Write-Verbose "Starting Crawler reindex if necessary"
                    Invoke-ISHCrawlerReIndex @ISHDeploymentSplat
                }

                Write-Verbose "Finished AfterInstall"
            }
            'ApplicationStart' {
                Write-Verbose "Starting ApplicationStart"

                $fullTextIndexDependecy = Get-ISHFullTextIndexExternalDependency
                Write-Debug "fullTextIndexDependecy=$fullTextIndexDependecy"
                if ($fullTextIndexDependecy -eq "ExternalEC2") {
                    Write-Verbose "Waiting for $fullTextIndexDependecy Full Text Index dependency to become ready"
                    Wait-ISHIntegrationFullTextIndex @ISHDeploymentSplat
                    Write-Verbose "$fullTextIndexDependecy Full Text Index dependency is ready"
                }

                Write-Verbose "Executing recipe's StartBeforeCore"
                Invoke-ISHManifestEvent -ManifestHash $recipeManifest -EventName "StartBeforeCore" @ISHDeploymentSplat

                Write-Verbose "Executing core's Start-ISH"
                Start-ISH @ISHDeploymentSplat

                Write-Verbose "Executing recipe's StartAfterCore"
                Invoke-ISHManifestEvent -ManifestHash $recipeManifest -EventName "StartAfterCore" @ISHDeploymentSplat

                Write-Verbose "Finished ApplicationStart"
            }
            'ValidateService' {
                Write-Verbose "Starting ValidateService"

                Write-Verbose "Executing recipe's Validate"
                Invoke-ISHManifestEvent -ManifestHash $recipeManifest -EventName "Validate" @ISHDeploymentSplat

                Write-Verbose "Finished ValidateService"
            }

        }
    }

    end {
        Remove-Item -Path ENV:\ISHBootstrap_Recipe_Type -ErrorAction SilentlyContinue
        Remove-Item -Path ENV:\ISHBootstrap_Recipe_Name -ErrorAction SilentlyContinue
        Remove-Item -Path ENV:\ISHBootstrap_Recipe_Version -ErrorAction SilentlyContinue
    }
}
