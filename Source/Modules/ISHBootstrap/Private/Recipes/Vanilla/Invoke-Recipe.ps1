Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

$recipeVersionMarkerName = "Recipe.Version"
$recipeVersion = "1.0"
Write-Debug "recipeVersionMarkerName=$recipeVersionMarkerName"
Write-Debug "recipeVersion=$recipeVersion"

Write-Debug "Testing marker Recipe.Version"
if (-not (Test-Marker -Name "Recipe.Version")) {
    Write-Debug "Marker Recipe.Version doesn't exist"
    $currentRecipeVersion = "0.0"
}
else {
    Write-Debug "Marker Recipe.Version exists"
    $currentRecipeVersion = Get-Marker -Name $recipeVersionMarkerName
}
Write-Debug "currentRecipeVersion=$currentRecipeVersion"

Write-Verbose "Found existing recipe version $currentRecipeVersion"
Write-Verbose "Recipe version is $recipeVersion"

if (([version]$currentRecipeVersion) -lt ([version]$recipeVersion)) {
    Write-Debug "Updating Marker Recipe.Version $recipeVersion"
    Set-Marker -Name $recipeVersionMarkerName -Value $recipeVersion
    Write-Verbose "Updated Marker Recipe.Version $recipeVersion"
}
else {
    Write-Verbose "Marker Recipe.Version is up to date"
}