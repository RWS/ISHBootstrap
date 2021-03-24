<#
.Synopsis
    Create a new Recipe with Publish metadata
.DESCRIPTION
    Create a new Recipe with Publish metadata
.EXAMPLE
    New-ISHDeploymentRecipe -ProjectName project -RecipeName qa -RecipeVersion 15.0.0
#>

Function New-ISHDeploymentRecipe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,
        [Parameter(Mandatory = $true)]
        [string]$RecipeName,
        [Parameter(Mandatory = $false)]
        [string]$RecipePath = ".\Recipe",
        [Parameter(Mandatory = $true)]
        [string]$RecipeVersion,
        [Parameter(Mandatory = $false)]
        [string]$Description
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $recipeSource = Resolve-Path "$PSScriptRoot\..\Private\Recipes\Vanilla"
        $manifestPath = Resolve-Path "$recipeSource\manifest.psd1"
        Write-Debug "Source manifestPath=$manifestPath"
        Write-Debug "RecipePath=$RecipePath"
        if (Test-Path "$RecipePath") {
            $recipeTarget = Resolve-Path "$RecipePath"
        }
        else {
            $recipeTarget = New-Item -Path $RecipePath -ItemType 'directory'
        }

        Write-Debug "recipeTarget=$recipeTarget"

        if (-not (Test-Path -Path $manifestPath)) {
            throw "$Path doesn't contain a manifest.psd1"
        }

        # Load and read the manifest
        $manifestContent = Get-Content -Path $manifestPath -Raw
        $manifestHash = Invoke-Expression -Command $manifestContent

        if (-not $manifestHash.ContainsKey("Type")) {
            throw "$manifestPath does not define type"
        }

        if ($manifestHash.Type -ne "ISHRecipe") {
            throw "$manifestPath is not of type ISHRecipe"
        }

        if ($Description) {
            $manifestHash.Description = $Description
        }
        else {
            $manifestHash.Description = "Recipe $RecipeName version $RecipeVersion for Project $ProjectName."
        }

        # Build the publish metadata
        $manifestHash["Publish"] = @{
            Name    = $RecipeName
            Version = $RecipeVersion
            Date    = (Get-Date).ToUniversalTime().ToString();
            Engine  = "1.0"
        }

        Copy-Item -Path "$recipeSource\*" -Destination "$recipeTarget" -Recurse -Force

        # Update the manifest with the extra information
        Export-ManifestHash -Hash $manifestHash -Path "$recipeTarget\manifest.psd1"
        Write-Verbose "Infused publish information to manifest file"

    }

    end {

    }

}