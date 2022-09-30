<#
# Copyright (c) 2022 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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
   Get core configuration from parameter store
.DESCRIPTION
   Get core configuration from parameter store. Consolidate the different values into one object
.EXAMPLE
   Get-ISHCoreConfiguration
#>
function Get-ISHCoreConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
        $projectStageKey = Get-Key -ProjectStage @ISHDeploymentSplat
        $ishKey = Get-Key -ISH @ISHDeploymentSplat
        Write-Debug "projectStageKey=$projectStageKey"
        Write-Debug "ishKey=$ishKey"
        $deploymentConfig = (Get-Variable -Name "ISHDeploymentConfigFilePath").Value -f ($ISHDeployment  -replace "^InfoShare$")
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
                    Count = 0
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

        # MSOLEDBSQL
        # E.g.Provider=MSOLEDBSQL.1;Password=*****;Persist Security Info=True;User ID=isource;Initial Catalog=ISH14DEV;Data Source=MECDEVDB05\SQL2017
        if ( $hash.Database.Type -eq 'oracle' ){
            $hash.Database.ConnectionString = "Provider=OraOLEDB.Oracle.1;Data Source=$($hash.Database.DataSource);Persist Security Info=True;User ID=$($hash.Database.Username);Password=$($hash.Database.Password)"
        }
        else {
            $hash.Database.ConnectionString="Provider=MSOLEDBSQL.1;Data Source=$($hash.Database.DataSource);Initial Catalog=$($hash.Database.InitialCatalog);Persist Security Info=True;User ID=$($hash.Database.Username);Password=$($hash.Database.Password)"
        }
        #Credetnials
        if (Test-KeyValuePS -Folder "$ishKey/Credentials/OSUser" -FilePath $deploymentConfig) {
            $hash.OSUser = @{
                Username = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Credentials/OSUser/Username" | Select-Object -ExpandProperty Value
                Password = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Credentials/OSUser/Password" | Select-Object -ExpandProperty Value
            }
            $osUserCredentials = New-PSCredential -Username $hash.OSUser.Username -Password $hash.OSUser.Password
            $hash.OSUser.Credential = Get-ISHNormalizedCredential -Credentials $osUserCredentials
            $hash.OSUser.NormalizedUsername = $hash.OSUser.Credential.Username
        }
        if (Test-KeyValuePS -Folder "$ishKey/Credentials/ServiceAdmin" -FilePath $deploymentConfig) {
            $hash.ServiceAdmin = @{
                Username = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Credentials/ServiceAdmin/Username" | Select-Object -ExpandProperty Value
                Password = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Credentials/ServiceAdmin/Password" | Select-Object -ExpandProperty Value
            }
            $hash.ServiceAdmin.Credential = New-PSCredential -Username $hash.ServiceAdmin.Username -Password $hash.ServiceAdmin.Password
        }
        if (Test-KeyValuePS -Folder "$ishKey/Credentials/ServiceUser" -FilePath $deploymentConfig) {
            $hash.ServiceUser = @{
                Username = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Credentials/ServiceUser/Username" | Select-Object -ExpandProperty Value
                Password = $configurationValues | Where-Object -Property Key -EQ "$ishKey/Credentials/ServiceUser/Password" | Select-Object -ExpandProperty Value
            }
            $hash.ServiceUser.Credential = New-PSCredential -Username $hash.ServiceUser.Username -Password $hash.ServiceUser.Password
        }
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
