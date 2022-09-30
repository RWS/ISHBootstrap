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
   Get the current version of the database
.DESCRIPTION
   Get the current version of the database
.EXAMPLE
   Get-ISHDatabaseVersion
#>
Function Get-ISHDatabaseVersion {
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

    # TODO - Replace SQL Server query with DBUT SaveInfoShareVersionHistoryXML (SCTCCM-300)
    process {
        $ishDB = Get-ISHIntegrationDB @ISHDeploymentSplat
        $engin = $ishDB | Select-Object -ExpandProperty Engine
        $connectionString = $ishDB | Select-Object -ExpandProperty RawConnectionString

        if ( $engin -eq 'oracle' ) {
            $sql = @"
SELECT * FROM 
(
    SELECT VERSION 
    FROM ISH_SETUP_HISTORY 
    WHERE STATUS = 'Completed' AND ACTION = 'DatabaseUpgrade' 
    ORDER BY CREATIONDATE DESC
) 
WHERE 
    ROWNUM = 1
"@
            $ishDBVersion = Invoke-OracleQuery -Sql $sql -ConnectionString $connectionString
            $ishDBVersion.VERSION
        }
        else {
            $sql = @"
SELECT Top 1 [VERSION]
FROM [dbo].[ISH_SETUP_HISTORY]
WHERE STATUS = 'Completed' AND ACTION = 'DatabaseUpgrade'
ORDER BY CREATIONDATE DESC
"@

            #region TODO Invoke-SqlServerQuery@InvokeQuery
            $invokeSqlServerQuerySplat = New-SqlServerQuerySplat -ConnectionString $connectionString
            #endregion

            $ishDBVersion = Invoke-SqlServerQuery -Sql $sql -NoTrans -Scalar @invokeSqlServerQuerySplat
            Write-Debug "ishDBVersion=$ishDBVersion"
            $ishDBVersion
        }
    }

    end {

    }
}
