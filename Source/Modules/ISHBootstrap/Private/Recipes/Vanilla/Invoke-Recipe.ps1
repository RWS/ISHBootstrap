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

Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

$recipeVersionMarkerName = "Recipe.Version"
$recipeVersion = "1.0"
Write-Debug "recipeVersionMarkerName=$recipeVersionMarkerName"
Write-Debug "recipeVersion=$recipeVersion"

Write-Debug "Testing marker Recipe.Version"
if (-not (Test-ISHMarker -Name "Recipe.Version")) {
    Write-Debug "Marker Recipe.Version doesn't exist"
    $currentRecipeVersion = "0.0"
}
else {
    Write-Debug "Marker Recipe.Version exists"
    $currentRecipeVersion = Get-ISHMarker -Name $recipeVersionMarkerName
}
Write-Debug "currentRecipeVersion=$currentRecipeVersion"

Write-Verbose "Found existing recipe version $currentRecipeVersion"
Write-Verbose "Recipe version is $recipeVersion"

#region Implementation
Write-Debug ("Copy-ISHFile -Force -ishCD $PSScriptRoot\CustomerSpecificFiles\FilesToCopy\")
Copy-ISHFile -Force -ishCD "$PSScriptRoot\CustomerSpecificFiles\FilesToCopy\"

$ISHData = Get-ISHIntegrationConfiguration

if (Test-ISHComponent -Name 'CM') {
    Enable-ISHUITranslationJob
    Enable-ISHExternalPreview
}

#endregion Implementation

if (([version]$currentRecipeVersion) -lt ([version]$recipeVersion)) {
    Write-Debug "Updating Marker Recipe.Version $recipeVersion"
    Set-ISHMarker -Name $recipeVersionMarkerName -Value $recipeVersion
    Write-Verbose "Updated Marker Recipe.Version $recipeVersion"
}
else {
    Write-Verbose "Marker Recipe.Version is up to date"
}
