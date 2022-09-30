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
   Set a proper Crawler registration in the database
.DESCRIPTION
   Set a proper Crawler registration in the database
.EXAMPLE
   Set-ISHDatabaseCrawlerRegistration
#>
Function Set-ISHDatabaseCrawlerRegistration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
    }

    process {
        <#
            The goal is to make sure there is only one valid Crawler registration in the datbase
            When there is exactly one crawler registration that is valid then no action is taken
            When not
            - then remove all registration if any
            - register the current one
        #>

        # TODO - Replace SQL Server query with method to retrieve the registered crawlers (SCTCCM-301)
        # Sql to count the number of crawler registrations
        $sqlCrawlerRegistrationCount = @"
SELECT COUNT(HOSTNAME)
FROM ISH_CRAWLER
"@
        Write-Debug "sqlCrawlerRegistrationCount=$(($sqlCrawlerRegistrationCount -split [System.Environment]::NewLine) -join ' ')"

        # Sql to count the number of valid crawler registrations
        $sqlValidCrawlerRegistrationCount = @"
SELECT COUNT(HOSTNAME)
FROM ISH_CRAWLER
WHERE HOSTNAME='InfoShare' AND CATALOG='InfoShare'
"@
        Write-Debug "sqlValidCrawlerRegistrationCount=$(($sqlValidCrawlerRegistrationCount -split [System.Environment]::NewLine) -join ' ')"
        $ishDB = Get-ISHIntegrationDB @ISHDeploymentSplat
        $engin = $ishDB | Select-Object -ExpandProperty Engine
        $connectionString = $ishDB | Select-Object -ExpandProperty RawConnectionString
        if ( $engin -eq 'oracle' ) {
            [int]$cralweRegistrationCount = (Invoke-OracleQuery -Sql $sqlCrawlerRegistrationCount -ConnectionString $connectionString)[0]
            Write-Debug "cralweRegistrationCount=$cralweRegistrationCount"

            [int]$validCralweRegistrationCount = (Invoke-OracleQuery -Sql $sqlValidCrawlerRegistrationCount -ConnectionString $connectionString)[0]
            Write-Debug "validCralweRegistrationCount=$validCralweRegistrationCount"
        }
        else {
            #region TODO Invoke-SqlServerQuery@InvokeQuery
            $invokeSqlServerQuerySplat = New-SqlServerQuerySplat -ConnectionString $connectionString  @ISHDeploymentSplat
            #endregion

            [int]$cralweRegistrationCount = Invoke-SqlServerQuery -Sql $sqlCrawlerRegistrationCount -NoTrans -Scalar @invokeSqlServerQuerySplat
            Write-Debug "cralweRegistrationCount=$cralweRegistrationCount"

            [int]$validCralweRegistrationCount = Invoke-SqlServerQuery -Sql $sqlValidCrawlerRegistrationCount -NoTrans -Scalar @invokeSqlServerQuerySplat
            Write-Debug "validCralweRegistrationCount=$validCralweRegistrationCount"
        }
        if ($cralweRegistrationCount -gt 1) {
            Write-Warning "More than 1 crawer registrations found in database"
            Invoke-ISHMaintenance -Crawler -UnRegisterAll @ISHDeploymentSplat
            Invoke-ISHMaintenance -Crawler -Register @ISHDeploymentSplat
        }
        elseif (($cralweRegistrationCount -eq 1) -and ($validCralweRegistrationCount -eq 1)) {
            Write-Verbose "Found proper crawler registrations"
        }
        elseif (($cralweRegistrationCount -eq 1) -and ($validCralweRegistrationCount -eq 0)) {
            Write-Warning "Found 1 invalid crawer registration found in database"
            Invoke-ISHMaintenance -Crawler -UnRegisterAll @ISHDeploymentSplat
            Invoke-ISHMaintenance -Crawler -Register @ISHDeploymentSplat
        }
        else {
            Write-Warning "No crawer registrations found in database"
            Invoke-ISHMaintenance -Crawler -Register @ISHDeploymentSplat
        }

    }

    end {

    }
}
