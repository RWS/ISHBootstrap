<#
# Copyright (c) 2014 All Rights Reserved by the SDL Group.
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

$repositoryPath=Resolve-Path "$PSScriptRoot\..\.."
$modulePath=Resolve-Path "$PSScriptRoot\..\Modules"

Import-Module "$modulePath\SDLDevTools" -Force

$reportToValidate=@()
Test-SDLOpenSourceHeader -FolderPath $repositoryPath -PassThru | ForEach-Object {
    $hash=@{}
    $hash.FilePath=$_.FilePath
    $hash.Format=$_.Format
    $hash.Error=$_.Error
    $hash.IsValid=$_.IsValid

    $reportToValidate+=$hash
}
Describe "Verify open source headers" {
    It "Test-SDLOpenSourceHeader <FilePath>" -TestCases $reportToValidate {
        param ($FilePath,$Format,$Error,$IsValid)
        if(-not $IsValid)
        {
            Write-Warning "$Error in $FilePath"
        }
        $IsValid | Should BeExactly $true
    }
}
