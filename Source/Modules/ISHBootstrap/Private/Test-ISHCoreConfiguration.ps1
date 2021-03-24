<#
.Synopsis
   Test what is changed from AWS SSM parameter store on the deployment
.DESCRIPTION
   Produce an object with what is changed from AWS SSM parameter store on the deployment
.EXAMPLE
   Test-ISHCoreConfiguration
#>
function Test-ISHCoreConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        $ConfigurationData = $null
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        if (-not $ConfigurationData) {
            $ConfigurationData = Get-ISHCoreConfiguration
        }

        $hash = @{
            EC2InitializedFromAMI = Test-Requirement -Marker -Name "ISH.EC2InitializedFromAMI"

            #Database
            Database              = (Get-ISHDeploymentParameters -Name connectstring -ValueOnly) -eq $ConfigurationData.Database.ConnectionString

            Crawler               = ($ConfigurationData.Service.Crawler.Count) -eq ((Get-ISHServiceCrawler).Count)
            TranslationBuilder    = ($ConfigurationData.Service.TranslationBuilder.Count) -eq ((Get-ISHServiceTranslationBuilder).Count)
            TranslationOrganizer  = ($ConfigurationData.Service.TranslationOrganizer.Count) -eq ((Get-ISHServiceTranslationOrganizer).Count)
            BackgroundTaskDefault = ($ConfigurationData.Service.BackgroundTaskDefault.Count) -eq ((Get-ISHServiceBackgroundTask | Where-Object -Property Role -EQ Default).Count)
            BackgroundTaskSingle  = ($ConfigurationData.Service.BackgroundTaskSingle.Count) -eq ((Get-ISHServiceBackgroundTask | Where-Object -Property Role -EQ Single).Count)
            BackgroundTaskMulti   = ($ConfigurationData.Service.BackgroundTaskMulti.Count) -eq ((Get-ISHServiceBackgroundTask | Where-Object -Property Role -EQ Multi).Count)
        }

        New-Object -TypeName PSObject -Property $hash

    }

    end {

    }
}