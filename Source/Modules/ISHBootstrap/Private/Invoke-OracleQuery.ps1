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
   Invoke Oracle query
.DESCRIPTION
   Invoke Oracle query
.EXAMPLE
   Invoke-OracleQuery -Sql 'SELECT 1 FROM DUAL;'
.EXAMPLE
   Invoke-OracleQuery -Sql 'SELECT 1 FROM DUAL;' -ConnectionString <connectionstring>
#>
function Invoke-OracleQuery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment,
        [Parameter(Mandatory = $false)]
        [string]$ConnectionString,
        [Parameter(Mandatory = $true)]
        [string]$Sql
    )
    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }

        if ( -not $ConnectionString ){
            $deployment = Get-ISHDeployment @ISHDeploymentSplat
            if ($deployment.SoftwareVersion.Major -lt 15) {
                $ConnectionString = Get-ISHIntegrationDB @ISHDeploymentSplat | Select-Object -ExpandProperty RawConnectionString
            }
            else {
                $ConnectionString = Get-ISHConnectionString -DatabasePurpose ContentManager @ISHDeploymentSplat | Select-Object -ExpandProperty RawConnectionString
            }
        }
    }
    process {
        $list = @()
        $ConnectionString -split ';' | ForEach-Object {
            $key = ($_ -split '=')[0]
            $value = ($_ -split '=')[1]
            switch ($key) {
                'Data Source' {
                    $list += "Data Source=$value"
                }
                'User ID' {
                    $list += "User ID=$value"
                }
                'Password' {
                    $list += "Password=$value"
                }
            }
        }
        $ConnectionString = $list -join ";"
        Add-Type -Path (Join-Path $PSScriptRoot "/lib/Oracle.ManagedDataAccess.dll")

        $ad = New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter($Sql, $connectionString)
        $ds = New-Object System.Data.DataSet
        $null = $ad.Fill($ds)
        return $ds.Tables[0]
    }
    end {

    }
}