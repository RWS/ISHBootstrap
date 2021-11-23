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
. "$here\..\Public\Get-UriStatus.ps1"

$randomUri = 'Uri' + (Get-random)
$maxIterations = 5

Describe "Wait-UriStatus" {
    BeforeEach {
        Set-Variable -Name "Iteration" -Value 1 -Scope Global
    }
    AfterEach {
        Remove-Variable -Name "Iteration" -Scope Global -ErrorAction SilentlyContinue
    }
    Mock "Get-UriStatus" {
        $iteration = Get-Variable -Name "Iteration" -Scope Global -ValueOnly
        Write-Debug "iteration=$iteration"
        if ($iteration -lt $maxIterations) {
            Set-Variable -Name "Iteration" -Value ($iteration + 1) -Scope Global
            0
        }
        else {
            200
        }
    }

    It "Wait-UriStatus -Seconds" {
        $measure = Measure-Command -Expression { Wait-UriStatus -Uri $randomUri -Status 200 -Seconds 1 }
        $iteration | Should BeExactly 5
        Assert-MockCalled -CommandName "Get-UriStatus" -Scope It -Exactly $maxIterations -ParameterFilter {
            $Uri -eq $randomUri
        }
    }
    It "Wait-UriStatus -Milliseconds" {
        $measure = Measure-Command -Expression { Wait-UriStatus -Uri $randomUri -Status 200 -Milliseconds 10 }
        $iteration | Should BeExactly 5
        Assert-MockCalled -CommandName "Get-UriStatus" -Scope It -Exactly $maxIterations -ParameterFilter {
            $Uri -eq $randomUri
        }
    }
}
