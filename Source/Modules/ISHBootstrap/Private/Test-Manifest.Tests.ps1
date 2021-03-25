<#
# Copyright (c) 2021 All Rights Reserved by the SDL Group.
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
. "$here\Test-Manifest"

$publishName = 'Name' + (Get-random)
$publishVersion = 'Version' + (Get-random)
$publishDate = 'Date' + (Get-random)
$publishEngine = 'Engine' + (Get-random)

function RenderManifest([string]$Type, [boolean]$IncludePublish) {

    $manifest = @"
@{
    Type="$Type"

"@

    if ($IncludePublish) {
        $manifest += @"

    Publish=@{
        Name="$publishName"
        Version="$publishVersion"
        Date="$publishDate"
        Engine="$publishEngine"
    }
"@
    }


    $manifest += @"

}
"@

    $manifest
}

Describe "Test-Manifest" {
    It "Test-Manifest Invalid" {
        $tempPath = [System.IO.Path]::GetTempFileName()
        RenderManifest ('Invalid' + (Get-random)) $false | Out-File $tempPath

        Test-Manifest -Path $tempPath | Should BeExactly $false
        Remove-Item -Path $tempPath -Force
    }
    It "Test-Manifest ISHRecipe" {
        $tempPath = [System.IO.Path]::GetTempFileName()
        RenderManifest "ISHRecipe" $false | Out-File $tempPath

        Test-Manifest -Path $tempPath | Should BeExactly $false
        Remove-Item -Path $tempPath -Force
    }
    It "Test-Manifest ISHRecipe+Publish" {
        $tempPath = [System.IO.Path]::GetTempFileName()
        RenderManifest "ISHRecipe" $true | Out-File $tempPath

        Test-Manifest -Path $tempPath | Should BeExactly $true
        Remove-Item -Path $tempPath -Force
    }
    It "Test-Manifest ISHCoreHotfix" {
        $tempPath = [System.IO.Path]::GetTempFileName()
        RenderManifest "ISHCoreHotfix" $false | Out-File $tempPath

        Test-Manifest -Path $tempPath | Should BeExactly $false
        Remove-Item -Path $tempPath -Force
    }
    It "Test-Manifest ISHCoreHotfix+Publish" {
        $tempPath = [System.IO.Path]::GetTempFileName()
        RenderManifest "ISHCoreHotfix" $true | Out-File $tempPath

        Test-Manifest -Path $tempPath | Should BeExactly $true
        Remove-Item -Path $tempPath -Force
    }
    It "Test-Manifest ISHHotfix" {
        $tempPath = [System.IO.Path]::GetTempFileName()
        RenderManifest "ISHHotfix" $false | Out-File $tempPath

        Test-Manifest -Path $tempPath | Should BeExactly $false
        Remove-Item -Path $tempPath -Force
    }
    It "Test-Manifest ISHHotfix+Metadata" {
        $tempPath = [System.IO.Path]::GetTempFileName()
        RenderManifest "ISHHotfix" $true | Out-File $tempPath

        Test-Manifest -Path $tempPath | Should BeExactly $true
        Remove-Item -Path $tempPath -Force
    }
}


