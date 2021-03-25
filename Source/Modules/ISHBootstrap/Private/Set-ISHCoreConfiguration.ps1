<#
# Copyright (c) 2021 All Rights Reserved by the SDL Group.
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
   Apply the core configuration from AWS SSM parameter store into the deployment
.DESCRIPTION
   Apply the core configuration from AWS SSM parameter store into the deployment
.EXAMPLE
   Set-ISHCoreConfiguration
#>
function Set-ISHCoreConfiguration {
    [CmdletBinding()]
    param(
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $configurationData = Get-ISHCoreConfiguration
        $testData = Test-ISHCoreConfiguration -ConfigurationData $configurationData

        #region logging
        Write-Debug "testData.HTTPSCertificate=$($testData.HTTPSCertificate)"
        Write-Debug "testData.IssuerCertificate=$($testData.IssuerCertificate)"
        Write-Debug "testData.ServiceCertificate=$($testData.ServiceCertificate)"
        Write-Debug "testData.Database=$($testData.Database)"
        Write-Debug "testData.Crawler=$($testData.Crawler)"
        Write-Debug "testData.TranslationBuilder=$($testData.TranslationBuilder)"
        Write-Debug "testData.TranslationOrganizer=$($testData.TranslationOrganizer)"
        Write-Debug "testData.BackgroundTaskDefault=$($testData.BackgroundTaskDefault)"
        Write-Debug "testData.BackgroundTaskSingle=$($testData.BackgroundTaskSingle)"
        Write-Debug "testData.BackgroundTaskMulti=$($testData.BackgroundTaskMulti)"
        Write-Debug "testData.EC2InitializedFromAMI=$($testData.EC2InitializedFromAMI)"
        #endregion

        #region AMI to Instance
        if (Test-RunOnEC2) {
            if (-not $testData.EC2InitializedFromAMI) {
                if ($configurationData.Hostname) {
                    Write-Debug "configurationData.Hostname=$($configurationData.Hostname)"
                    Initialize-ISHEC2FromAMI -Hostname $configurationData.Hostname
                    Write-Verbose "Initialized EC2 from AMI"
                }
            }
        }
        #endregion

        #region Certificate

        if ((-not $testData.HTTPSCertificate) -and $configurationData.Certificate.HTTPS) {
            Write-Debug "Installing HTTPSCertificate"
            $thumbprint = $configurationData.Certificate.HTTPS.Thumbprint
            Write-Debug "thumbprint=$thumbprint"

            $filePath = Join-Path $env:TEMP "HTTPS.$($thumbprint).pfx"
            Write-Debug "filePath=$filePath"
            if (-not (Test-Path -Path "Cert:\LocalMachine\My\$thumbprint")) {
                $pfxPassword = ConvertTo-SecureString -String $configurationData.Certificate.HTTPS.PfxPassword -AsPlainText -Force
                Write-Debug "Saving certificate to $filePath"
                if ($null -ne $configurationData.Certificate.HTTPS.PfxBlob) {
                    [System.IO.File]::WriteAllBytes($filePath, $configurationData.Certificate.HTTPS.PfxBlob)
                }
                else {
                    $null = Read-S3Object -BucketName $configurationData.Certificate.HTTPS.PfxBase64BucketName -Key $configurationData.Certificate.HTTPS.PfxBase64Key -File $filePath
                }
                Write-Debug "Installing certificate from $filePath"
                $certificate = Import-PfxCertificate -FilePath $filePath -CertStoreLocation Cert:\LocalMachine\My -Password $pfxPassword
                Write-Verbose "Installed certificate from $filePath"
            }

            Set-IISCertificate -Thumbprint $thumbprint
            Write-Verbose "Configured IIS Certificate"

            Write-Debug "Removing $filePath"
            Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
        }
        if ((-not $testData.IssuerCertificate) -and $configurationData.Certificate.ISHSTS) {
            Write-Debug "Installing IssuerCertificate"
            $thumbprint = $configurationData.Certificate.ISHSTS.Thumbprint
            Write-Debug "thumbprint=$thumbprint"

            $filePath = Join-Path $env:TEMP "ISHSTS.$($thumbprint).pfx"
            Write-Debug "filePath=$filePath"
            if (-not (Test-Path -Path "Cert:\LocalMachine\My\$thumbprint")) {
                $pfxPassword = ConvertTo-SecureString -String $configurationData.Certificate.ISHSTS.PfxPassword -AsPlainText -Force
                Write-Debug "Saving certificate to $filePath"
                if ($null -ne $configurationData.Certificate.ISHSTS.PfxBlob) {
                    [System.IO.File]::WriteAllBytes($filePath, $configurationData.Certificate.ISHSTS.PfxBlob)
                }
                else {
                    $null = Read-S3Object -BucketName $configurationData.Certificate.ISHSTS.PfxBase64BucketName -Key $configurationData.Certificate.ISHSTS.PfxBase64Key -File $filePath
                }
                Write-Debug "Installing certificate from $filePath"
                $certificate = Import-PfxCertificate -FilePath $filePath -CertStoreLocation Cert:\LocalMachine\My -Password $pfxPassword
                Write-Verbose "Installed certificate from $filePath"
            }

            Set-ISHSTSConfiguration -TokenSigningCertificateThumbprint $thumbprint
            Write-Verbose "Configured ISHSTS configuration"

            $issuerName = "$($date).ISHBootstrap"
            Write-Debug "issuerName=$issuerName"
            Set-ISHIntegrationSTSCertificate -Issuer $issuerName -Thumbprint $thumbprint
            Write-Verbose "Configured IIS integration STS Certificate"

            Write-Debug "Removing $filePath"
            Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
        }
        if ((-not $testData.ServiceCertificate) -and $configurationData.Certificate.ISHWS) {
            Write-Debug "Installing ServiceCertificate"
            $thumbprint = $configurationData.Certificate.ISHWS.Thumbprint
            Write-Debug "thumbprint=$thumbprint"

            $filePath = Join-Path $env:TEMP "ISHWS.$($thumbprint).pfx"
            Write-Debug "filePath=$filePath"
            if (-not (Test-Path -Path "Cert:\LocalMachine\My\$thumbprint")) {
                $pfxPassword = ConvertTo-SecureString -String $configurationData.Certificate.ISHWS.PfxPassword -AsPlainText -Force
                Write-Debug "Saving certificate to $filePath"
                if ($null -ne $configurationData.Certificate.ISHWS.PfxBlob) {
                    [System.IO.File]::WriteAllBytes($filePath, $configurationData.Certificate.ISHWS.PfxBlob)
                }
                else {
                    $null = Read-S3Object -BucketName $configurationData.Certificate.ISHWS.PfxBase64BucketName -Key $configurationData.Certificate.ISHWS.PfxBase64Key -File $filePath
                }
                Write-Debug "Installing certificate from $filePath"
                $certificate = Import-PfxCertificate -FilePath $filePath -CertStoreLocation Cert:\LocalMachine\My -Password $pfxPassword
                Write-Verbose "Installed certificate from $filePath"
            }

            Set-ISHAPIWCFServiceCertificate -Thumbprint $thumbprint
            Write-Verbose "Configured ISHAPI Service Certificate"

            Write-Debug "Removing $filePath"
            Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
        }

        #region TODO ApplicationPoolRenegade
        if ((-not $testData.HTTPSCertificate) -or (-not $testData.IssuerCertificate) -or (-not $testData.ServiceCertificate)) {
            Write-Debug "Querying for renegate w3wp.exe processes"
            if (Get-Process -Name w3wp -IncludeUserName -ErrorAction SilentlyContinue | Where-Object -Property UserName -eq $configurationData.OSUser.NormalizedUsername) {
                Write-Warning "Found renegate w3wp.exe processes. Stopping their application pools."
                Stop-ISHWeb
            }
        }
        #endregion

        #region Initialize Crawler
        Set-ISHServiceCrawler -Hostname "InfoShare" -Catalog "InfoShare"
        Write-Verbose "Configured Crawler"

        #endregion

        #region Database

        if ((-not $testData.Database)) {
            # If the DataSource is '(local)', use the local (ISHSQLEXPRESS) mock database as (demo) database.
            # The values from AWS SSM parameter store will be used to construct the connectionstring (same as for an external database)
            if ($configurationData.Database.DataSource -eq "(local)") {
                Write-Warning "The DataSource equals '(local)' (in e.g. AWS SSM parameter store)."
                Write-Warning "Using the local mock database as (demo) database."
                Write-Verbose "Using local (demo) database"
                Write-Verbose "Validation local (demo) database"
                $SqlServerVersion = $configurationData.Database.Type -replace "sqlserver", ""
                if (-not (Test-ISHRequirement -Marker -Name MSSQL.Version -Value $SqlServerVersion)) {
                    $message = "The configuration expects a local MS SQL Server (version '$SqlServerVersion')."
                    $message += " The used image with ImageId '$($configurationData.ImageId)' does not contain a local database or it is the incorrect version."
                    Throw $message
                }
                Write-Verbose "Initializing local (demo) database"
                $dbScriptsPath = "C:\Provision\ISHBootstrap\Source\Builders\Database"
                # Creating the OSUser login and the SQL server login and user as configured in parameter store.
                if ($configurationData.OSUser.Credential.Username) {
                    $osUser = $configurationData.OSUser.Credential.Username
                }
                else {
                    $osUser = Get-ISHDeploymentParameters -Name osuser -ShowPassword -ValueOnly
                }
                if ($configurationData.Database.UserName) {
                    $dbUser = $configurationData.Database.UserName
                }
                else {
                    $dbUser = Get-ISHDeploymentParameters -Name databaseuser -ShowPassword -ValueOnly
                }
                if ($configurationData.Database.Password) {
                    $dbPassword = $configurationData.Database.Password
                }
                else {
                    $dbPassword = Get-ISHDeploymentParameters -Name databasepassword -ShowPassword -ValueOnly
                }
                & $dbScriptsPath\Initialize-MockDatabase.ps1 -OSUserSqlUser $osUser -SqlUsername $dbUser -SqlPassword $dbPassword
            }

            #TODO ISHDeploy-SCTCM-123
            # Workaround for the execution timeout of 3 seconds for testing the database connection.
            # https://stash.sdl.com/projects/TS/repos/ishdeploy/diff/Source/ISHDeploy/Data/Managers/DatabaseManager.cs?until=eaf9bfa444709210449c5431d0837f576ab97020
            $a = 1
            $max = 5
            $sleep = 10
            Do {
                If ($a -gt $max) { break }
                Write-Verbose "Configuring Database integration - Attempt $($a) of $($max)"
                try {
                    Set-ISHIntegrationDB -ConnectionString $configurationData.Database.ConnectionString -Engine $configurationData.Database.Type -Raw
                    Write-Verbose "Configured Database integration - Attempt $($a) of $($max) - Successful"
                    break
                }
                catch {
                    Write-Verbose "Configuring Database integration - Attempt $($a) of $($max) - Failed"
                    write-Verbose "Exception Type: $($_.Exception.GetType().FullName)"
                    write-Verbose "Exception Message: $($_.Exception.Message)"
                    Write-Verbose "Going to sleep for $($sleep) seconds"
                    Start-Sleep -Seconds $sleep
                }
                finally {
                    $a++
                }
            } While ($a -le $max)

            #Set-ISHIntegrationDB -ConnectionString $configurationData.Database.ConnectionString -Engine $configurationData.Database.Type -Raw
            Write-Verbose "Configured Database integration"
        }

        #endregion

        #region Service Count

        if (-not $testData.Crawler) {
            Write-Debug "configurationData.Service.Crawler.Count=$($configurationData.Service.Crawler.Count)"
            Set-ISHServiceCrawler -Count $configurationData.Service.Crawler.Count
            Write-Verbose "Configured Crawler service count"
        }
        if (-not $testData.TranslationBuilder) {
            Write-Debug "configurationData.Service.TranslationBuilder.Count=$($configurationData.Service.TranslationBuilder.Count)"
            Set-ISHServiceTranslationBuilder -Count $configurationData.Service.TranslationBuilder.Count
            Write-Verbose "Configured TranslationBuilder service count"
        }
        if (-not $testData.TranslationOrganizer) {
            Write-Debug "configurationData.Service.TranslationOrganizer.Count=$($configurationData.Service.TranslationOrganizer.Count)"
            Set-ISHServiceTranslationOrganizer -Count $configurationData.Service.TranslationOrganizer.Count
            Write-Verbose "Configured TranslationOrganizer service count"
        }

        # Default role exists in code to make sure we remove it the first time because it's part of Vanilla
        # CloudFormation Architecture expects Single,Multi,Custom1 and Custom2 background task roles
        foreach ($role in (Get-Tag -Name ISHComponent-BackgroundTask).Split(',')) {
            $backgroundTask = "BackgroundTask$role"
            Write-Debug "configurationData.Service.$backgroundTask.Count=$($configurationData.Service."$backgroundTask".Count)"
            if ($configurationData.Service."$backgroundTask".Count -gt 0) {
                Set-ISHServiceBackgroundTask -Role $role -Count "$configurationData.Service.$backgroundTask".Count
                Write-Verbose "Configured BackgroundTask with $role role service count"
            }
            else {
                Remove-ISHServiceBackgroundTask -Role $role
                Write-Verbose "Removed BackgroundTask with $role role service"
            }
        }

        #endregion

        #region Component

        if (
            (Test-ISHComponent -Name CM) -or
            (Test-ISHComponent -Name CS) -or
            (Test-ISHComponent -Name WS) -or
            (Test-ISHComponent -Name STS)
        ) {
            Enable-ISHIISAppPool
            Write-Verbose "Enabled IIS ISH Application pools"
        }
        else {
            Disable-ISHIISAppPool
            Write-Verbose "Disabled IIS ISH Application pools"
        }

        Enable-ISHCOMPlus
        Write-Verbose "Enabled COM+"

        if (Test-ISHComponent -Name Crawler) {
            Enable-ISHServiceCrawler
            Write-Verbose "Enabled Crawler component"
        }
        else {
            Disable-ISHServiceCrawler
            Write-Verbose "Disabled Crawler component"
        }

        if (Test-ISHComponent -Name FullTextIndex) {
            #region Initialize the ports for FullTextIndex

            if (-not (Test-ISHRequirement -Marker -Name "ISH.InitializedNetFullTextIndex")) {
                Initialize-ISHNetFullTextIndex
                Write-Verbose "Initialized network connectivity for FullTextIndex"
            }

            #endregion

            Enable-ISHServiceFullTextIndex
            Write-Verbose "Enabled FullTextIndex component"
        }
        else {
            Disable-ISHServiceFullTextIndex
            Write-Verbose "Disabled FullTextIndex component"

            # Redirect FullTextIndex uri to uri on other server that has the FullTextIndex component enabled
            $fullTextIndexUri = Get-ISHServiceFullTextIndexUri
            Write-Debug "fullTextIndexUri=$fullTextIndexUri"
            Set-ISHIntegrationFullTextIndex -Uri $fullTextIndexUri
            Write-Verbose "Configured FullTextIndex integration to $fullTextIndexUri"
        }

        if (Test-ISHComponent -Name TranslationBuilder) {
            Enable-ISHServiceTranslationBuilder
            Write-Verbose "Enabled TranslationBuilder component"
        }
        else {
            Disable-ISHServiceTranslationBuilder
            Write-Verbose "Disabled TranslationBuilder component"
        }

        if (Test-ISHComponent -Name TranslationOrganizer) {
            Enable-ISHServiceTranslationOrganizer
            Write-Verbose "Enabled TranslationOrganizer component"
        }
        else {
            Disable-ISHServiceTranslationOrganizer
            Write-Verbose "Disabled TranslationOrganizer component"
        }

        foreach ($role in (Get-Tag -Name ISHComponent-BackgroundTask).Split(',')) {
            if (Test-ISHComponent -Name BackgroundTask -Role $role) {
                Enable-ISHServiceBackgroundTask -Role $role
                Write-Verbose "Enabled BackgroundTask for role=$role component"
            }
            else {
                Disable-ISHServiceBackgroundTask -Role $role
                Write-Verbose "Disabled BackgroundTask for role=$role component"
            }
        }

        #endregion

    }

    end {

    }
}
