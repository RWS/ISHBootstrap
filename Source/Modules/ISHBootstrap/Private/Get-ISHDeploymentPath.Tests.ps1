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

$webPath = 'WebPath' + (Get-random)
$appPath = 'AppPath' + (Get-random)

Describe "Get-ISHDeploymentPath" {
    Mock "Get-ISHDeployment" {
        [pscustomobject]@{
            WebPath = $webPath
            AppPath = $appPath
        }
    }

    It "Get-ISHDeploymentPath -EnterViaUI" {
        $actual = Get-ISHDeploymentPath -EnterViaUI
        $actual.AbsolutePath | Should Be "$webPath\Author\EnterViaUI"
        $actual.RelativePath | Should Be "Author\EnterViaUI"
    }
    It "Get-ISHDeploymentPath -JettyIPAccess" {
        $actual = Get-ISHDeploymentPath -JettyIPAccess
        $actual.AbsolutePath | Should Be "$appPath\Utilities\SolrLucene\Jetty\etc\jetty-ipaccess.xml"
        $actual.RelativePath | Should Be "Utilities\SolrLucene\Jetty\etc\jetty-ipaccess.xml"
    }
}
