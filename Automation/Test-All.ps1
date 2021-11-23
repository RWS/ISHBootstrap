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

#Requires -Module Pester

Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("None","Temp","ScriptRoot")]
    [string]$OutputPath="None"
)
$failedCount=0
$pesterHash=@{
    Script="$PSScriptRoot\Tests"
    PassThru=$true
}

$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".").Replace(".ps1", "")
switch ($OutputPath)
{
    'None' {$outputFile=$null}
    'ScriptRoot' {$outputFile="$PSScriptRoot\$sut.xml"}
    'Temp' {$outputFile="$env:TEMP\$sut.xml"}
}

if($outputFile)
{
    $pesterHash.OutputFormat="NUnitXml"
    $pesterHash.OutputFile=$outputFile
}

$pesterResult=Invoke-Pester @pesterHash
$pesterResult | Add-Member -Name "TestResultPath" -Value $outputFile -MemberType NoteProperty
if($pesterResult.FailedCount -gt 0)
{
    $failedCount+=$pesterResult.FailedCount
}

if($failedCount -gt 0)
{
    throw "Test errors $failedCount detected"
}
return $failedCount
