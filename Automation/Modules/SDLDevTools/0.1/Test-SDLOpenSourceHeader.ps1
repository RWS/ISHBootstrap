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

Function Test-SDLOpenSourceHeader {
    param(
        [Parameter(Mandatory=$true,ParameterSetName="Folder")]
        [string]$FolderPath,
        [Parameter(Mandatory=$true,ParameterSetName="File")]
        [string]$FilePath,
        [Parameter(Mandatory=$false,ParameterSetName="File")]
        [Parameter(Mandatory=$false,ParameterSetName="Folder")]
        [switch]$PassThru=$false
    )
    begin {
        . $PSScriptRoot\Get-SDLOpenSourceHeader.ps1
        . $PSScriptRoot\Get-SDLOpenSourceHeaderFormat.ps1
    }
    process {
        switch($PSCmdlet.ParameterSetName)
        {
            'Folder' {
                Get-ChildItem $FolderPath -Filter "*.*" -Recurse -File | ForEach-Object {
                    if(-not ($_.FullName))
                    {
                        continue
                    }
                    Test-SDLOpenSourceHeader -FilePath ($_.FullName) -PassThru:$PassThru
                }
            }
            'File' {
                Write-Debug "Calculating format for $FilePath"
                $fileFormat=Get-SDLOpenSourceHeaderFormat -FilePath $FilePath
                if(-not $fileFormat)
                {
                     Write-Warning "Skipped $FilePath"
                     break
                }
                Write-Debug "Testing header for $FilePath"
                $header = Get-SDLOpenSourceHeader -Format $fileFormat
                $content=Get-Content $FilePath

                $hash=[ordered]@{
                    FilePath=$FilePath
                    Format=$fileFormat
                    Error=$null
                }
                if($content.Count -lt $header.Count)
                {
                    $hash.Error="Line count less than header"
                }
                else
                {
                    for($i=0;$i -lt $header.Count;$i++)
                    {
                        if($header[$i] -ne $content[$i])
                        {
                            $hash.Error="Mismatch on line $($i+1)"
                            break
                        }
                    }
                }
                $hash.IsValid=$hash.Error -eq $null
                Write-Verbose "Tested header for $FilePath"
                if($PassThru)
                {
                    New-Object -TypeName PSObject -Property $hash
                }
                else
                {
                    if(-not $hash.IsValid)
                    {
                        Write-Error "Failed for $FilePath because of `"$($hash.Error)`"."
                    }
                    $hash.IsValid
                }
            }
        }
    }

    end {

    }
}
