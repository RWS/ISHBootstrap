<#
# Copyright (c) 2021 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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
. "$here\New-SqlServerQuerySplat.ps1"

$server = 'Server' + (Get-random)
$database = 'Database' + (Get-random)
$username = 'Username' + (Get-random)
$password = 'Password' + (Get-random)

$version = 'Version' + (Get-random)

Describe "Get-ISHDatabaseVersion" {
    Mock "Invoke-SqlServerQuery" {
        $version
    }
    Mock "New-SqlServerQuerySplat" {
        @{
            Server     = $server
            Database   = $database
            Credential = New-PSCredential -Username $username -Password $password
        }
    }
    It "Get-ISHDatabaseVersion" {
        $actualVersion = Get-ISHDatabaseVersion
        $actualVersion | Should BeExactly $version
        Assert-MockCalled -CommandName "Invoke-SqlServerQuery" -Scope It -Exactly 1 -ParameterFilter {
            $sql -and $NoTrans -and $Scalar -and $Server -and $Database -and $Credential
        }
    }
}


