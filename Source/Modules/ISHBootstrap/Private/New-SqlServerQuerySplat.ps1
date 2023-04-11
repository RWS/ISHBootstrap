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

#region TODO Invoke-SqlServerQuery@InvokeQuery

<#
.Synopsis
   Create a splat for the InvokeQuery:Invoke-SqlServerQuery connection
.DESCRIPTION
   Create a splat for the InvokeQuery:Invoke-SqlServerQuery connection
.EXAMPLE
   New-SqlServerQuerySplat
#>
function New-SqlServerQuerySplat {
    [OutputType([Collections.Hashtable])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment,
        [Parameter(Mandatory = $false)]
        [string]$ConnectionString
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
        $splat = @{

        }
        $credentialSplat = @{

        }
        $ConnectionString -split ';' | ForEach-Object {
            $key = ($_ -split '=')[0]
            $value = ($_ -split '=')[1]
            switch ($key) {
                'Data Source' {
                    $splat.Server = $value
                }
                'Initial Catalog' {
                    $splat.Database = $value
                }
                'User ID' {
                    $credentialSplat.Username = $value
                }
                'Password' {
                    $credentialSplat.Password = $value
                }
            }
        }
        $splat.Credential = New-PSCredential @credentialSplat

        $splat
    }

    end {

    }
}

#endregion
