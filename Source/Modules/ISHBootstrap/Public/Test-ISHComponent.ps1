<#
.Synopsis
   Test if the system is configured with the component
.DESCRIPTION
   Test if the system is configured with the component
.EXAMPLE
   Test-ISHComponent -Name "DatabaseUpgrade"
.EXAMPLE
   Test-ISHComponent -Name "BackgroundTask" -Role Default
#>
Function Test-ISHComponent {
    [CmdletBinding()]
    [OutputType([Boolean])]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Not BackgroundTask")]
        [Parameter(Mandatory = $true, ParameterSetName = "BackgroundTask")]
        [ValidateSet("DatabaseUpgrade", "CM", "CS", "WS", "STS", "Crawler", "FullTextIndex", "TranslationBuilder", "TranslationOrganizer", "BackgroundTask", "FontoContentQuality", "FontoDeltaXml", "FontoDocumentHistory", "FontoReview", "FontoSpellChecker")]
        [string]$Name,
        [Parameter(Mandatory = $true, ParameterSetName = "BackgroundTask")]
        [string]$Role
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $tagNamePrefix = "ISHComponent-"
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'Not BackgroundTask' {
                Test-Tag -Name "$tagNamePrefix$Name"
            }
            'BackgroundTask' {
                if (Test-Tag -Name "$tagNamePrefix$Name") {
                    $roles = (Get-Tag -Name "$tagNamePrefix$Name") -split ','
                }
                $roles -contains $Role
            }
        }
    }

    end {

    }
}
