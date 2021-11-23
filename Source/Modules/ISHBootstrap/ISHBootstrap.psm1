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

<#PSScriptInfo
.DESCRIPTION PowerShell module for ISHBootstrap
.VERSION 0.1
#>

New-Variable -Name 'ISHDeploymentConfigFilePath' -Value "$env:ProgramData\ISHBootstrap\config-docs-project.json" -Scope Script -Force

$public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -Exclude @("*NotReady*","*.Tests.ps1"))
$private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -Exclude @("*NotReady*","*.Tests.ps1"))

Foreach($import in @($public + $private))
{
    . $import.FullName
}

Export-ModuleMember -Function $public.BaseName
