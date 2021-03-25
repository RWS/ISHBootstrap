<#
# Copyright (c) 2021 All Rights Reserved by the SDL Group.
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
   Invoke-ISHCodeDeployHook -ApplicationStop -RootPath rootpath
.EXAMPLE
   Invoke-ISHCodeDeployHook -BeforeInstall -RootPath rootpath
.EXAMPLE
   Invoke-ISHCodeDeployHook -AfterInstall -RootPath rootpath
.EXAMPLE
   Invoke-ISHCodeDeployHook -ApplicationStart -RootPath rootpath
.EXAMPLE
   Invoke-ISHCodeDeployHook -ValidateService -RootPath rootpath
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
        [string]$RootPath
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        Write-Debug "RootPath=$RootPath"

    }

    process {
        $manifests = Get-ChildItem -Path $RootPath -Filter "manifest.psd1" -Depth 1 | Where-Object {
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
            throw "Only one recipe allowed in $RootPath"
        }
        if ($recipeManifest) {
            Write-Debug "Validating recipe $($recipeManifest.FilePath)"

            $recipePublishMetadata = $recipeManifest["Publish"]
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
                if (-not (Test-Requirement -ISH -Major $major -Minor $minor -Build $build -Revision $revision)) {
                    throw "Product version (major,minor,build,revision)=($major,$minor,$build,$revision) in recipe's manifest prerequisite version is not met"
                }
            }
        }
        Invoke-ISHManifestEvent -Manifest $recipeManifest -EventName "PreRequisite"

        switch ($PSCmdlet.ParameterSetName) {
            'ApplicationStop' {
                Write-Verbose "Starting ApplicationStop"

                Write-Verbose "Executing recipe's StopBeforeCore"
                Invoke-ISHManifestEvent -Manifest $recipeManifest -EventName "StopBeforeCore"

                Write-Verbose "Executing core's Stop-ISHDeployment"
                Stop-ISH

                Write-Verbose "Executing recipe's StopAfterCore"
                Invoke-ISHManifestEvent -Manifest $recipeManifest -EventName "StopAfterCore"

                Write-Verbose "Finished ApplicationStop"
            }
            'BeforeInstall' {
                Write-Verbose "Starting BeforeInstall"
                Write-Verbose "Finished BeforeInstall"

            }
            'AfterInstall' {
                Write-Verbose "Starting AfterInstall"

                Write-Verbose "Executing core's Set-ISHCoreConfiguration"
                Set-ISHCoreConfiguration

                Write-Verbose "Executing core's Set-ISHIntegrationConfiguration"
                Set-ISHIntegrationConfiguration

                Write-Verbose "Executing recipe's Execute"
                Invoke-ISHManifestEvent -Manifest $recipeManifest -EventName "Execute"

                # Block for Database upgrade
                if (Test-ISHComponent -Name DatabaseUpgrade) {
                    #region Database Upgrade
                    Write-Verbose "Executing recipe's DatabaseUpgradeBeforeCore"
                    Invoke-ISHManifestEvent -Manifest $recipeManifest -EventName "DatabaseUpgradeBeforeCore"

                    Write-Verbose "Executing core's Update-ISHDB"
                    Update-ISHDB

                    Write-Verbose "Executing recipe's DatabaseUpgradeAfterCore"
                    Invoke-ISHManifestEvent -Manifest $recipeManifest -EventName "DatabaseUpgradeAfterCore"

                    #endregion

                    #region Database update
                    try {
                        Write-Verbose "Starting ISHCM Web application pools"
                        Start-ISHWeb

                        Write-Verbose "Waiting for ISHCM Web application pools"
                        Wait-ISHWeb

                        Write-Verbose "Executing recipe's DatabaseUpdateBeforeCore"
                        Invoke-ISHManifestEvent -Manifest $recipeManifest -EventName "DatabaseUpdateBeforeCore"

                        Write-Verbose "Executing core's Update-ISHDBConfiguration"
                        Update-ISHDBConfiguration

                        Write-Verbose "Executing recipe's DatabaseUpdateAfterCore"
                        Invoke-ISHManifestEvent -Manifest $recipeManifest -EventName "DatabaseUpdateAfterCore"
                    }
                    finally {
                        Write-Verbose "Stopping ISHCM Web application pools"
                        Stop-ISHWeb
                    }

                    #endregion
                }

                # Handle the Crawler registrations and Reindex if necessary
                if (Test-ISHComponent -Name DatabaseUpgrade) {
                    Write-Verbose "Making sure there is one Crawler registration in the database"
                    Set-ISHDatabaseCrawlerRegistration
                }
                if (Test-ISHComponent -Name FullTextIndex) {
                    Write-Verbose "Starting Crawler reindex if necessary"
                    Invoke-ISHCrawlerReIndex
                }

                Write-Verbose "Finished AfterInstall"
            }
            'ApplicationStart' {
                Write-Verbose "Starting ApplicationStart"

                $fullTextIndexDependecy = Get-ISHFullTextIndexExternalDependency
                Write-Debug "fullTextIndexDependecy=$fullTextIndexDependecy"
                if ($fullTextIndexDependecy -eq "ExternalEC2") {
                    Write-Verbose "Waiting for $fullTextIndexDependecy Full Text Index dependency to become ready"
                    Wait-ISHIntegrationFullTextIndex
                    Write-Verbose "$fullTextIndexDependecy Full Text Index dependency is ready"
                }

                Write-Verbose "Executing recipe's StartBeforeCore"
                Invoke-ISHManifestEvent -Manifest $recipeManifest -EventName "StartBeforeCore"

                Write-Verbose "Executing core's Start-ISH"
                Start-ISH

                #region TODO COMPLUS-Occasional-Unpredictable-Fail
                Restart-ISHComponentCOMPlus
                #endregion

                Write-Verbose "Executing recipe's StartAfterCore"
                Invoke-ISHManifestEvent -Manifest $recipeManifest -EventName "StartAfterCore"

                Write-Verbose "Finished ApplicationStart"
            }
            'ValidateService' {
                Write-Verbose "Starting ValidateService"

                Write-Verbose "Executing recipe's Validate"
                Invoke-ISHManifestEvent -Manifest $recipeManifest -EventName "Validate"

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
