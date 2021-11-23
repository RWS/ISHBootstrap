<#
.Synopsis
   Publish the ISHBootstrap powershell module to one of the supported repositories
.DESCRIPTION
   Publish the ISHBootstrap powershell module to one of the supported repositories
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Nexus", "PSGallery")]
    [string]$Repository,
    [Parameter(Mandatory = $false)]
    [switch]$PreRelease = $false #Future usage, to support pubishing prerelase versions to e.g. PSGallery (and Nexus?)
)

if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

$publishModulePath = "$PSScriptRoot"

switch ($Repository) {
    "Nexus" {
        Write-Host "Register the $Repository repository if needed"
        Get-PSRepository -WarningAction SilentlyContinue | Where-Object { $_.Name -eq $Repository } | Unregister-PSRepository

        $psRepositoryHashSDLNexus = @{
            SourceLocation     = "https://nexus.sdl.com/service/local/nuget/releases_powershell/"
            PublishLocation    = "https://nexus.sdl.com/service/local/nuget/releases_powershell/"
            InstallationPolicy = "Trusted"
        }
        Register-PSRepository @psRepositoryHashSDLNexus -Name  $Repository

        $RepositoryToPublish = $Repository
        $ApiKey = "$env:APIKEY"

        # Install the required dependend modules otherwise Test-ModuleManifest fails (https://github.com/PowerShell/PowerShell/issues/7722)
        & $publishModulePath/../Source/Builders/Default/Install-ISHBootstrapPrerequisites.ps1 -FTP -ISHVersion 14.0.3

        & $publishModulePath/Publish-Module.ps1 -DevRepository $RepositoryToPublish -NuGetApiKey $ApiKey
        break
    }
    "PSGallery" {
        # Explicitely set to $null, Publish-Module is executed with -WhatIf (https://jira.sdl.com/browse/SYS-2796)
        Write-Warning "Force omitting NuGetApiKey. Publish-Module will be executed with -WhatIf for PSGallery (See SYS-2796)."
        #$ApiKey = "$env:APIKEY_DOCS_PSGALLERY"
        $ApiKey = $null
        # Install the required dependend modules otherwise Test-ModuleManifest fails (https://github.com/PowerShell/PowerShell/issues/7722)
        & $publishModulePath/../Source/Builders/Default/Install-ISHBootstrapPrerequisites.ps1 -FTP -ISHVersion 14.0.3

        if ($null -eq $ApiKey ) {
            & $publishModulePath/Publish-Module.ps1
        }
        else {
            & $publishModulePath/Publish-Module.ps1 -NuGetApiKey $ApiKey
        }
        break
    }
    default {
        # Should not happen, because of the ValidateSet on the Repository parameter.
        throw "Unsupported Repository used: $Repository"
        break
    }
}