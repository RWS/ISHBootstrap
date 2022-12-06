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
. $here\Get-StageFolderPath.ps1
. $here\Get-JSONContentPath.ps1
. $here\Set-JSONContent.ps1
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

function random([string]$name) {
    $random = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object { [char]$_ })
    $name + "-" + $random
}

$Type = 'Test' + (Get-random)

Describe "Get-JSONContent" {
    $stageModulePath = "$($env:ProgramData)\ISHBootstrap.Pester"
    Remove-Item -Path $stageModulePath -Force -Recurse -ErrorAction SilentlyContinue
    It "Doesn't throw" {
        { Get-JSONContent -Type $Type } | Should Not Throw
    }
    It "Test file path" {
        $expectedPath = Join-Path -Path $stageModulePath -ChildPath "$Type.json"
        Test-Path -Path $expectedPath | Should BeExactly $false
    }
    It "Isn't null or empty but exactly {}" {
        (Get-JSONContent -Type $Type | ConvertTo-Json -Compress) | Should BeExactly "{}"
    }
}
