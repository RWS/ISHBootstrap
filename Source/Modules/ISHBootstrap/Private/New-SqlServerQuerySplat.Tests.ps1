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

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\New-PSCredential.ps1"

$server = 'Server' + (Get-random)
$database = 'Database' + (Get-random)
$username = 'Username' + (Get-random)
$password = 'Password' + (Get-random)

Describe "New-SqlServerQuerySplat" {
    Mock "Get-ISHIntegrationDB" {
        $mockConnectionStringFragments = @(
            "$('Name' + (Get-random))=$('Value' + (Get-random))"
            "Data Source=$server"
            "$('Name' + (Get-random))=$('Value' + (Get-random))"
            "Initial Catalog=$database"
            "$('Name' + (Get-random))=$('Value' + (Get-random))"
            "User ID=$username"
            "$('Name' + (Get-random))=$('Value' + (Get-random))"
            "Password=$Password"
            "$('Name' + (Get-random))=$('Value' + (Get-random))"
        )
        [pscustomobject]@{
            RawConnectionString = ($mockConnectionStringFragments | Sort-Object { Get-Random }) -join ';'
        }
    }
    It "New-SqlServerQuerySplat" {
        $splat = New-SqlServerQuerySplat
        $splat.Server | Should BeExactly $server
        $splat.Database | Should BeExactly $database
        $splat.Credential.Username | Should BeExactly $username
    }
}


