<#
.Synopsis
   Tags locally the system with components
.DESCRIPTION
   When not hosted on EC2 use this cmdlet to mimic a component configuration
.EXAMPLE
   Set-ISHRoleComponentTags -AllInOne
.EXAMPLE
   Set-ISHRoleComponentTags -Batch
#>
Function Set-ISHRoleComponentTags {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = "Dev")]
        [switch]$Dev = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Main")]
        [switch]$Main = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Batch")]
        [switch]$Batch = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "AllInOne")]
        [switch]$AllInOne = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "OneBE-MultipleFE")]
        [switch]$OneBE = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "OneBE-MultipleFE")]
        [Parameter(Mandatory = $false, ParameterSetName = "MultipleBEMulti-OneBESingle-MultipleFE")]
        [switch]$MultipleFE = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "MultipleBEMulti-OneBESingle-MultipleFE")]
        [switch]$MultipleBEMulti = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "MultipleBEMulti-OneBESingle-MultipleFE")]
        [switch]$OneBESingle = $false
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        if ($Dev) {
            Set-ISHComponent -All
            Set-ISHComponent -BackgroundTask -Role @("Default", "Publish")

            Set-Tag -Name "ISHRole" -Value "Dev"
        }

        if ($Main) {
            Set-ISHComponent -All
            Set-ISHComponent -BackgroundTask -Role 'Default'

            Set-Tag -Name "ISHRole" -Value "Main"
        }

        if ($Batch) {
            Set-ISHComponent -Web
            Set-ISHComponent -TranslationJob
            Set-ISHComponent -BackgroundTask -Role 'Publish'

            Set-Tag -Name "ISHRole" -Value "Batch"
        }

        if ($AllInOne) {
            Set-ISHComponent -All
            Set-ISHComponent -BackgroundTask -Role 'Default'

            Set-Tag -Name "ISHRole" -Value "AllInOne"
        }

        if ($OneBE) {
            Set-ISHComponent -All
            Set-ISHComponent -BackgroundTask -Role @("Multi", "Single")

            Set-Tag -Name "ISHRole" -Value "OneBE"
        }

        if ($MultipleFE) {
            Set-ISHComponent -Web
            Set-ISHComponent -WebCS
            Set-ISHComponent -FontoContentQuality
            Set-ISHComponent -FontoDeltaXml
            Set-ISHComponent -FontoDocumentHistory
            Set-ISHComponent -FontoReview
            Set-ISHComponent -FontoSpellChecker

            Set-Tag -Name "ISHRole" -Value "MultipleFE"
        }

        if ($MultipleBEMulti) {
            Set-ISHComponent -Web
            Set-ISHComponent -WebCS
            Set-ISHComponent -FontoContentQuality
            Set-ISHComponent -FontoDeltaXml
            Set-ISHComponent -FontoDocumentHistory
            Set-ISHComponent -FontoReview
            Set-ISHComponent -FontoSpellChecker
            Set-ISHComponent -TranslationBuilder
            Set-ISHComponent -TranslationOrganizer
            Set-ISHComponent -All
            Set-ISHComponent -BackgroundTask -Role 'Multi'

            Set-Tag -Name "ISHRole" -Value "MultipleBEMulti"
        }

        if ($OneBESingle) {
            Set-ISHComponent -Web
            Set-ISHComponent -WebCS
            Set-ISHComponent -FontoContentQuality
            Set-ISHComponent -FontoDeltaXml
            Set-ISHComponent -FontoDocumentHistory
            Set-ISHComponent -FontoReview
            Set-ISHComponent -FontoSpellChecker
            Set-ISHComponent -DatabaseUpgrade
            Set-ISHComponent -FullTextIndex
            Set-ISHComponent -Crawler
            Set-ISHComponent -All
            Set-ISHComponent -BackgroundTask -Role 'Single'

            Set-Tag -Name "ISHRole" -Value "OneBESingle"
        }

    }

    end {

    }
}
