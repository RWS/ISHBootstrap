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

#Requires -Modules @{ ModuleName="PowerShellGet"; ModuleVersion="2.2.5" }
#Requires -Version 7.0

param(
    [Parameter(Mandatory = $false, ParameterSetName = "Public")]
    [Parameter(Mandatory = $false, ParameterSetName = "Public+Internal")]
    [string]$NuGetApiKey = $null,
    [Parameter(Mandatory = $true, ParameterSetName = "Public+Internal")]
    [ValidateScript( { $_ -ne "PSGallery" })]
    [string]$DevRepository,
    [Parameter(Mandatory = $false, ParameterSetName = "Public")]
    [Parameter(Mandatory = $false, ParameterSetName = "Public+Internal")]
    [bool]$Prerelease = $true
)
Set-StrictMode -Version latest

Import-Module -Name PowerShellGet -Version 2.2.5 -Force
Install-Module -Name SemVerPS

$moduleNameToPublish = "ISHBootstrap"
switch ($PSCmdlet.ParameterSetName) {
    'Public' {
        $repository = "PSGallery"
        $moduleName = $moduleNameToPublish
        break;
    }
    'Public+Internal' {
        # Publishing internally (Nexus) allows only prerelease versions.
        # PSGallery allows prereleases and full releases
        # To avoid version/upgrade issues when using both repositories
        $Prerelease = $true
        Write-Warning "Publishing internally (Nexus) allows only prerelease versions. Enforcing prerelease version."
        $repository = $DevRepository
        $moduleName = $moduleNameToPublish
        break
    }
}

$changeLogPath = "$PSScriptRoot\..\CHANGELOG.md"
$changeLog = Get-Content -Path $changeLogPath

try {
    $progressActivity = "Publish $moduleName"
    Write-Progress -Activity $progressActivity

    $tempPath = [System.Io.Path]::GetTempPath()
    $tempWorkFolderPath = Join-Path $tempPath "$moduleName-Publish"
    if (Test-Path $tempWorkFolderPath) {
        Remove-Item -Path $tempWorkFolderPath -Recurse -Force
    }
    New-Item -Path $tempWorkFolderPath -ItemType Directory | Out-Null
    Write-Verbose "Temporary working folder $tempWorkFolderPath is ready"

    $modulePath = Join-Path $tempWorkFolderPath $moduleName
    New-Item -Path $modulePath -ItemType Directory | Out-Null
    Write-Verbose "Temporary working folder $modulePath is ready"

    Copy-Item -Path "$PSScriptRoot\..\Source\Modules\ISHBootstrap\*" -Destination $modulePath -Recurse
    Get-ChildItem -Path $modulePath -Filter "ISHBootstrap.psm1" | Where-Object -Property Name -Ne "$($moduleName).psm1" | remove-Item -Force

    $psm1Path = Join-Path $modulePath "$moduleName.psm1"
    $metadataPath = Join-Path $modulePath "metadata.ps1"
    $metadataContent = Get-Content -Path $metadataPath -Raw
    $versionRegEx = "\.VERSION (?<Major>([0-9]+))\.(?<Minor>([0-9]+))\.(?<Build>([0-9]+))"
    if ($metadataContent -notmatch $versionRegEx) {
        Write-Error "$metadataPath doesn't contain (correct) script info .VERSION"
        return -1
    }
    $sourceMajor = [int]$Matches["Major"]
    $sourceMinor = [int]$Matches["Minor"]
    $sourcePatch = [int]$Matches["Build"]
    $sourcePreRelease = "update"
    $sourceVersion = "$sourceMajor.$sourceMinor.$sourcePatch"
    $sourceVersionToCompare = [semver]$sourceVersion

    Write-Debug "sourceMajor=$sourceMajor"
    Write-Debug "sourceMinor=$sourceMinor"
    Write-Debug "sourcePatch=$sourcePatch"
    Write-Debug "sourceVersion=$sourceVersion"

    # Versioning
    # $Prerelease (OR 'internal')           : 2.0.0-update3260250   (2.0.0 from metadata.ps1, 3260250 = buildnr of the day      -> This is a prerelease (Nexus or PSGallery)
    # NOT $Prerelease (AND NOT 'internal')  : 2.0.0                 (2.0.0 from metadata.ps1)                                   -> This is a release to PSGallery
    if ($Prerelease) {
        $startYear = "2021"
        $date = (Get-Date).ToUniversalTime()
        $build = [string](1200 * ($date.Year - $startYear) + $date.Month * 100 + $date.Day)
        $build += $date.ToString("HHmm")
        $sourcePreRelease += "$build"
        $sourceVersionToCompare = [semver]"$sourceVersion-$sourcePreRelease"
        Write-Verbose "Increased $moduleName version with prerelease $sourceVersionToCompare"
    }
    Write-Debug "sourceVersionToCompare=$sourceVersionToCompare"

    #region query
    Write-Debug "Querying $moduleName in Repository $repository"
    Write-Progress -Activity $progressActivity -Status "Querying..."
    $repositoryModule = Find-Module -Name $moduleName -Repository $repository -AllowPrerelease:$Prerelease -ErrorAction SilentlyContinue
    Write-Verbose "Queried $moduleName in Repository $repository"
    $shouldTryPublish = $false

    if ($repositoryModule) {
        $publishedVersion = [semver]$repositoryModule.Version

        Write-Verbose "Found existing published module with version $publishedVersion"

        if ($sourceVersionToCompare -gt $publishedVersion) {
            Write-Verbose "Source version $sourceVersionToCompare is greater than the published version $publishedVersion"
            $shouldTryPublish = $true
        }
        else {
            Write-Warning "Source version $sourceVersionToCompare is less than or equal to the already published version $publishedVersion. Will skip publishing."
        }
    }
    else {
        Write-Verbose "Module is not yet published to the $repository repository"
        $shouldTryPublish = $true
    }
    #endregion

    #region files to exclude from the published module

    #Remove metadata.ps1, since it is only used to track/handle the module version when generating the Module Manifest
    Remove-Item -Path $metadataPath -Force

    #endregion files to exclude from the published module

    #region manifest
    Write-Debug "Generating manifest"

    Import-Module $psm1Path -Force
    $exportedNames = Get-Command -Module $moduleName | Select-Object -Property Name | ForEach-Object { $_.Name }
    $psm1Name = $moduleName + ".psm1"
    $psd1Path = Join-Path $modulePath "$moduleName.psd1"

    $requiredModules = @(
        "Pester"
        "ISHDeploy"
        "ISHRemote"
        "InvokeQuery"
        "PoshPrivilege"
        "WcfPS"
        "PSHosts"
    )
    $externalModules = @(
        "Pester"
        "InvokeQuery"
        "PoshPrivilege"
        "WcfPS"
        "PSHosts"
    )

    # Generating module release notes from the latest changes from the CHANGELOG.md
    $possition = "None"
    $releaseNotes = foreach ($line in $changeLog) {
        if ($line.StartsWith("## release v")) {
            if ($possition -eq "None") {
                $possition = "This Version"
            }
            else {
                $possition = "Next Version"
            }
            continue
        }
        If ($possition -eq "This Version") {
            if ($line) {
                $line
            }
        }
    }
    $releaseNotes += @(
        ""
        "https://github.com/RWS/ISHBootstrap/blob/master/CHANGELOG.md"
    )

    $hash = @{
        "Author"                     = "RWS Group for and on behalf of its affiliates and subsidiaries"
        "CompanyName"                = "RWS Group for and on behalf of its affiliates and subsidiaries"
        "Copyright"                  = "All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries"
        "RootModule"                 = $psm1Name
        "Description"                = "Automation module to standardize how configuration and customizations are deployed on Tridion Docs 14+ (Tridion Docs, Knowledge Center Content Manager, LiveContent Architect, Trisoft InfoShare)"
        "Guid"                       = "70f59757-c17f-43c8-be34-8c64c615f3d8"
        "ModuleVersion"              = $sourceVersion
        "Path"                       = $psd1Path
        "LicenseUri"                 = "https://github.com/RWS/ISHBootstrap/blob/master/LICENSE"
        "ProjectUri"                 = "https://github.com/RWS/ISHBootstrap/"
        "ReleaseNotes"               = $releaseNotes -join [System.Environment]::NewLine
        "CmdletsToExport"            = $exportedNames
        "FunctionsToExport"          = $exportedNames
        "RequiredModules"            = $requiredModules
        "ExternalModuleDependencies" = $externalModules
        "CompatiblePSEditions"       = "Desktop"
        "PowerShellVersion"          = "5.1"
    }
    if ( $PSCmdlet.ParameterSetName -eq 'Public' ) {
        $hash.Remove("ExternalModuleDependencies")
    }

    if ($Prerelease) {
        $hash.Add("Prerelease", $sourcePreRelease)
    }

    New-ModuleManifest @hash

    Test-ModuleManifest -Path $psd1Path -Verbose

    Write-Verbose "Generated manifest"
    #endregion

    if ($shouldTryPublish) {
        #region publish
        Write-Debug "Publishing $moduleName"
        Write-Progress -Activity $progressActivity -Status "Publishing..."
        if ($NuGetApiKey) {
            Publish-Module -Repository $repository -Path $modulePath -NuGetApiKey $NuGetApiKey -Confirm:$false
        }
        else {
            Write-Warning "No NuGetApiKey provided. Executing Publish-Module with -WhatIf"
            Publish-Module -Repository $repository -Path $modulePath -NuGetApiKey "MockKey" -WhatIf -Confirm:$false
        }
        Write-Verbose "Published $moduleName"
        #endregion
    }
}
finally {
    Write-Progress -Activity $progressActivity -Completed
}
