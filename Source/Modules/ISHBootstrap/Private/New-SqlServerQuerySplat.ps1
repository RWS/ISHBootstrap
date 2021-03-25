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
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $connectionString = Get-ISHIntegrationDB | Select-Object -ExpandProperty RawConnectionString

        $splat = @{

        }
        $credentialSplat = @{

        }
        $connectionString -split ';' | ForEach-Object {
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
