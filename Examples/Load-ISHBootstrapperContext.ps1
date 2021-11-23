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

param(
    [Parameter(Mandatory=$true,ParameterSetName="Name")]
    [ValidateNotNullOrEmpty()]
    [string]$JSONFile,
    [Parameter(Mandatory=$true,ParameterSetName="Path")]
    [ValidateNotNullOrEmpty()]
    [string]$JSONPath,
    [Parameter(Mandatory=$true,ParameterSetName="Content")]
    [ValidateNotNullOrEmpty()]
    $JSON,
    [Parameter(Mandatory=$true,ParameterSetName="Content")]
    [ValidateNotNullOrEmpty()]
    [string]$FolderPath
)
try
{
    if($PSCmdlet.ParameterSetName -eq "Name")
    {
        $JSONPath="$PSScriptRoot\$JSONFile"
        $FolderPath=$PSScriptRoot
        $JSON = Get-Content -Path $JSONPath | ConvertFrom-Json 
    }
    if($PSCmdlet.ParameterSetName -eq "Path")
    {
        $FolderPath=Split-Path -Parent $JSONPath
        $uri = [System.Uri]"file://$JSONPath"
        Write-Debug "jsonPath=$JSONPath"
        Write-Debug "uri=$($uri.AbsoluteUri)"

        $client = New-Object System.Net.Webclient
        $JSON = $client.DownloadString($uri.AbsoluteUri)
    }

    $variableName="__ISHBootstrapper_Data__"
	if($JSON -is [string])
    {
        $JSON=$JSON| ConvertFrom-Json
    }
    $JSON | Add-Member NoteProperty "FolderPath" -Value $FolderPath
    Set-Variable $variableName -Value $JSON -Scope Global -Force

    Write-Host "ISHBootstrapper initialized in variable $variableName."
}
finally
{

}
