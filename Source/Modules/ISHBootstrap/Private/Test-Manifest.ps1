<#
.Synopsis
   Test if the manifest is valid
.DESCRIPTION
   Test if the manifest is one of the ISHRecipe, ISHCoreHotfix or ISHHotfix
.EXAMPLE
   Test-Manifest -Path path
#>
Function Test-Manifest {
    [OutputType([Boolean])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $manifestPath = Split-Path $Path -Parent
        Write-Debug "manifestPath=$manifestPath"

        $manifestContent = Get-Content -Path $Path -Raw
        $manifestHash = Invoke-Expression -Command $manifestContent

    }

    process {
        $validType = $false
        $validPublish = $false

        if ($manifestHash.ContainsKey("Type")) {
            Write-Debug "manifestHash.Type=$($manifestHash.Type)"
            $validType = $manifestHash.Type -in @("ISHRecipe", "ISHCoreHotfix", "ISHHotfix")
        }
        else {
            Write-Debug "Does not contain Type"
        }

        if ($manifestHash.ContainsKey("Publish")) {
            $validPublish = $manifestHash.Publish.Contains("Name") -and $manifestHash.Publish.Contains("Version") -and $manifestHash.Publish.Contains("Date") -and $manifestHash.Publish.Contains("Engine")
        }
        else {
            Write-Debug "Does not contain publish metadata"
        }

        $validType -and $validPublish
    }

    end {

    }
}