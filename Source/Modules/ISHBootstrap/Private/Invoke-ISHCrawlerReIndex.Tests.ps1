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
. "$here\..\Private\Set-ISHMarker.ps1"
. "$here\..\Public\Test-ISHRequirement.ps1"

Describe "Invoke-ISHCrawlerReIndex" {
    Mock "Invoke-ISHMaintenance" {

    }
    Mock "Set-ISHMarker" {
    }
    It "Invoke-ISHCrawlerReIndex - First time" {
        Mock "Test-ISHRequirement" {
            if($Marker -and ($Name -eq "ISH.EC2InvokedCrawlerReindex"))
            {
                $false
            }
            else
            {
                throw "Mock parameter $Name not expected"
            }
        }
        Invoke-ISHCrawlerReIndex
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 1 -ParameterFilter {
            $Crawler -and $ReIndex
        }
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 1
        Assert-MockCalled -CommandName "Set-ISHMarker" -Scope It -Exactly 1 -ParameterFilter {
            $Name -eq "ISH.EC2InvokedCrawlerReindex"
        }
        Assert-MockCalled -CommandName "Set-ISHMarker" -Scope It -Exactly 1
    }
    It "Invoke-ISHCrawlerReIndex - Not first time" {
        Mock "Test-ISHRequirement" {
            if($Marker -and ($Name -eq "ISH.EC2InvokedCrawlerReindex"))
            {
                $true
            }
            else
            {
                throw "Mock parameter $Name not expected"
            }
        }
        Invoke-ISHCrawlerReIndex
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 0
        Assert-MockCalled -CommandName "Set-ISHMarker" -Scope It -Exactly 0
    }
}
