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
. "$here\Get-StageFolderPath.ps1"

function random([string]$name) {
    $random = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object { [char]$_ })
    $name + "-" + $random
}

$Type = 'Test' + (Get-random)

Describe "Get-JSONContentPath" {
    $stageModulePath = "$($env:ProgramData)\ISHBootstrap.Pester"
    Remove-Item -Path $stageModulePath -Force -Recurse -ErrorAction SilentlyContinue
    It "Doesn't throw" {
        { Get-JSONContentPath -Type $Type } | Should Not Throw
    }
    It "Get-JSONContentPath -Type $Type" {
        $expectedPath = Join-Path -Path $stageModulePath -ChildPath "$Type.json"
        Get-JSONContentPath -Type $Type | Should BeExactly $expectedPath
    }
}


