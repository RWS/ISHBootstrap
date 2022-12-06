<#
# Copyright (c) 2022 All Rights Reserved by the RWS Group.
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
    Create a new base recipe.
.DESCRIPTION
    This cmdlet will create a base recipe which contains metadata files and event handlers.
    Base recipe do not provide any configuration logic but rahter general skeleton which
    can be extended with project specific configuration scripting or files.
.PARAMETER ProjectName
    Name of the project to which this recipe belongs.
.PARAMETER RecipeName
    Name of the recipe.
.PARAMETER RecipePath
    Directory where base recipe will be generated.
.PARAMETER RecipeVersion
    Version of the recipe package. Not same as product version.
.PARAMETER Description
    Recipe description that will be added to metadata file.
.EXAMPLE
    New-ISHDeploymentRecipe -ProjectName project -RecipeName qa -RecipeVersion 1.0
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
