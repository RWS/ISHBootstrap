<#
.Synopsis
   Get core configuration from parameter store
.DESCRIPTION
   Get core configuration from parameter store. Consolidate the different values into one object
.EXAMPLE
   Get-ISHCoreConfiguration
#>
function Get-ISHCoreConfiguration {
    [CmdletBinding()]
    param(
    )

    begin {
        $projectStageKey = Get-Key -ProjectStage
        $ishKey = Get-Key -ISH
        Write-Debug "projectStageKey=$projectStageKey"
        Write-Debug "ishKey=$ishKey"
        $deploymentConfig = (Get-Variable -Name "ISHDeployemntConfigFile").Value
        Write-Debug "deploymentConfig=$deploymentConfig"
    }

    process {
        Write-Debug "Retrieving recursevely from $projectStageKey"
        $configurationValues = Get-KeyValuePS -Key $projectStageKey -Recurse -FilePath $deploymentConfig
        Write-Debug "configurationValues.Count=$($configurationValues.Count)"
        $hash = @{
            Hostname = $configurationValues | Where-Object -Property Key -EQ "$projectStageKey/Hostname" | Select-Object -ExpandProperty Value

            #Database
            Database = @{
                DataSource     = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Integration/Database/SQLServer/DataSource" | Select-Object -ExpandProperty Value
                InitialCatalog = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Integration/Database/SQLServer/InitialCatalog" | Select-Object -ExpandProperty Value
                Password       = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Integration/Database/SQLServer/Password" | Select-Object -ExpandProperty Value
                Username       = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Integration/Database/SQLServer/Username" | Select-Object -ExpandProperty Value
                Type           = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Integration/Database/SQLServer/Type" | Select-Object -ExpandProperty Value
            }
            #Services
            Service  = @{
                Crawler               = @{
                    Count = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Component/Crawler/Count" | Select-Object -ExpandProperty Value
                }
                TranslationBuilder    = @{
                    Count = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Component/TranslationBuilder/Count" | Select-Object -ExpandProperty Value
                }
                TranslationOrganizer  = @{
                    Count = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Component/TranslationOrganizer/Count" | Select-Object -ExpandProperty Value
                }
                BackgroundTaskDefault = @{
                    Count = 1
                }
                BackgroundTaskPublish = @{
                    Count = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Component/BackgroundTask-Publish/Count" | Select-Object -ExpandProperty Value
                }
                BackgroundTaskSingle  = @{
                    Count = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Component/BackgroundTask-Single/Count" | Select-Object -ExpandProperty Value
                }
                BackgroundTaskMulti   = @{
                    Count = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Component/BackgroundTask-Multi/Count" | Select-Object -ExpandProperty Value
                }
            }
            ImageId  = $configurationValues | Where-Object -Property Key -EQ "$ishKey/ImageId" | Select-Object -ExpandProperty Value
            Certificate = @{}
        }

        # SQLOLEDB
        # E.g.Provider=SQLOLEDB.1;Password=isource;Persist Security Info=True;User ID=isource;Initial Catalog=ISH12PROD;Data Source=MECDEVDB05\SQL2014SP1
        $hash.Database.ConnectionString = "Provider=SQLOLEDB.1;Data Source=$($hash.Database.DataSource);Initial Catalog=$($hash.Database.InitialCatalog);Persist Security Info=True;User ID=$($hash.Database.Username);Password=$($hash.Database.Password)"
        # MSOLEDBSQL
        # E.g.Provider=MSOLEDBSQL.1;Password=isource;Persist Security Info=True;User ID=isource;Initial Catalog=ISH14DEV;Data Source=MECDEVDB05\SQL2017
        # $hash.Database.ConnectionString="Provider=MSOLEDBSQL.1;Data Source=$($hash.Database.DataSource);Initial Catalog=$($hash.Database.InitialCatalog);Persist Security Info=True;User ID=$($hash.Database.Username);Password=$($hash.Database.Password)"


        #Certificates
        if (Test-KeyValuePS -Key "$projectStageKey/Certificate/HTTPS/PfxBase64BucketName" -FilePath $deploymentConfig) {
            $hash.Certificate.HTTPS = @{
                PfxBase64BucketName = Get-KeyValuePS -Key "$projectStageKey/Certificate/HTTPS/PfxBase64BucketName" -FilePath $deploymentConfig | Select-Object -ExpandProperty Value
                PfxBase64Key        = Get-KeyValuePS -Key "$projectStageKey/Certificate/HTTPS/PfxBase64Key" -FilePath $deploymentConfig | Select-Object -ExpandProperty Value
                PfxPassword         = $configurationValues | Where-Object -Property Key -EQ "$projectStageKey/Certificate/HTTPS/PfxPassword" | Select-Object -ExpandProperty Value
                Thumbprint          = $configurationValues | Where-Object -Property Key -EQ "$projectStageKey/Certificate/HTTPS/Thumbprint" | Select-Object -ExpandProperty Value
            }
        }
        if (Test-KeyValuePS -Key "$projectStageKey/Certificate/ISHWS/PfxBase64BucketName" -FilePath $deploymentConfig) {
            $hash.Certificate.ISHWS = @{
                PfxBase64BucketName = Get-KeyValuePS -Key "$projectStageKey/Certificate/ISHWS/PfxBase64BucketName" -FilePath $deploymentConfig | Select-Object -ExpandProperty Value
                PfxBase64Key        = Get-KeyValuePS -Key "$projectStageKey/Certificate/ISHWS/PfxBase64Key" -FilePath $deploymentConfig | Select-Object -ExpandProperty Value
                PfxPassword         = $configurationValues | Where-Object -Property Key -EQ "$projectStageKey/Certificate/ISHWS/PfxPassword" | Select-Object -ExpandProperty Value
                Thumbprint          = $configurationValues | Where-Object -Property Key -EQ "$projectStageKey/Certificate/ISHWS/Thumbprint" | Select-Object -ExpandProperty Value
            }
        }
        if (Test-KeyValuePS -Key "$projectStageKey/Certificate/ISHSTS/PfxBase64BucketName" -FilePath $deploymentConfig) {
            $hash.Certificate.ISHSTS = @{
                PfxBase64BucketName = Get-KeyValuePS -Key "$projectStageKey/Certificate/ISHSTS/PfxBase64BucketName" -FilePath $deploymentConfig | Select-Object -ExpandProperty Value
                PfxBase64Key        = Get-KeyValuePS -Key "$projectStageKey/Certificate/ISHSTS/PfxBase64Key" -FilePath $deploymentConfig | Select-Object -ExpandProperty Value
                PfxPassword         = $configurationValues | Where-Object -Property Key -EQ "$projectStageKey/Certificate/ISHSTS/PfxPassword" | Select-Object -ExpandProperty Value
                Thumbprint          = $configurationValues | Where-Object -Property Key -EQ "$projectStageKey/Certificate/ISHSTS/Thumbprint" | Select-Object -ExpandProperty Value
            }
        }

        Write-Debug "Hash ready"

        New-Object -TypeName PSObject -Property $hash
    }

    end {

    }
}
