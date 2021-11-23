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
. "$here\..\Public\Test-RunOnEC2.ps1"
. "$here\..\Public\Test-ISHComponent.ps1"


Describe "Get-ISHFullTextIndexExternalDependency - Mock EC2 - FullTextIndex component enabled" {
    Mock "Test-RunOnEC2" {
        $true
    }
    It "Get-ISHFullTextIndexExternalDependency - FullTextIndex component enabled" {
        Mock "Test-ISHComponent" {
            if ($Name -eq "FullTextIndex") {
                $true
            }
            else {
                throw "$Name is not an expected mocked parameter value"
            }
        }
        Get-ISHFullTextIndexExternalDependency | Should BeExactly "Local"
        Assert-MockCalled -CommandName "Test-RunOnEC2" -Scope It -Exactly 1
        Assert-MockCalled -CommandName "Test-ISHComponent" -Scope It -Exactly 1 -ParameterFilter {
            $Name -eq "FullTextIndex"
        }
    }
    It "Get-ISHFullTextIndexExternalDependency - FullTextIndex component disabled" {
        Mock "Test-ISHComponent" {
            if ($Name -eq "FullTextIndex") {
                $false
            }
            else {
                throw "$Name is not an expected mocked parameter value"
            }
        }
        Get-ISHFullTextIndexExternalDependency | Should BeExactly "ExternalEC2"
        Assert-MockCalled -CommandName "Test-RunOnEC2" -Scope It -Exactly 1
        Assert-MockCalled -CommandName "Test-ISHComponent" -Scope It -Exactly 1 -ParameterFilter {
            $Name -eq "FullTextIndex"
        }
    }
}

Describe "Get-ISHFullTextIndexExternalDependency - Not EC2 - FullTextIndex component enabled" {
    Mock "Test-RunOnEC2" {
        $false
    }
    It "Get-ISHFullTextIndexExternalDependency - FullTextIndex component enabled" {
        Mock "Test-ISHComponent" {
            if ($Name -eq "FullTextIndex") {
                $true
            }
            else {
                throw "$Name is not an expected mocked parameter value"
            }
        }
        Get-ISHFullTextIndexExternalDependency | Should BeExactly "Local"
        Assert-MockCalled -CommandName "Test-RunOnEC2" -Scope It -Exactly 1
        Assert-MockCalled -CommandName "Test-ISHComponent" -Scope It -Exactly 1 -ParameterFilter {
            $Name -eq "FullTextIndex"
        }
    }
    It "Get-ISHFullTextIndexExternalDependency - FullTextIndex component disabled" {
        Mock "Test-ISHComponent" {
            if ($Name -eq "FullTextIndex") {
                $false
            }
            else {
                throw "$Name is not an expected mocked parameter value"
            }
        }
        Get-ISHFullTextIndexExternalDependency | Should BeExactly "None"
        Assert-MockCalled -CommandName "Test-RunOnEC2" -Scope It -Exactly 1
        Assert-MockCalled -CommandName "Test-ISHComponent" -Scope It -Exactly 1 -ParameterFilter {
            $Name -eq "FullTextIndex"
        }
    }
}

