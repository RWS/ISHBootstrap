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

Function Set-SDLOpenSourceHeader {
    param(
        [Parameter(Mandatory=$true,ParameterSetName="Folder")]
        [string]$FolderPath,
        [Parameter(Mandatory=$true,ParameterSetName="File")]
        [string]$FilePath,
        [Parameter(Mandatory=$false)]
        [switch]$WhatIf=$false
    )
    begin {
        . $PSScriptRoot\Get-SDLOpenSourceHeader.ps1
        . $PSScriptRoot\Test-SDLOpenSourceHeader.ps1
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
                    Set-SDLOpenSourceHeader -FilePath ($_.FullName) -WhatIf:$WhatIf
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
                if(Test-SDLOpenSourceHeader -FilePath $FilePath -ErrorAction SilentlyContinue)
                {
                    Write-Warning "Header detected in $FilePath. Skipped."
                    break
                }

                Write-Debug "Setting header for $FilePath"
                $header = Get-SDLOpenSourceHeader -Format $fileFormat
                $newContent=($header + (Get-Content $FilePath)) 
                if($WhatIf)
                {
                    Write-Host "What if: Performing the operation "Set Content" on target `"Path: $FilePath`"."
                }
                else
                {
                    [System.IO.File]::WriteAllLines($FilePath,$newContent)
            
                    # http://stackoverflow.com/questions/10480673/find-and-replace-in-files-fails
                    #$newContent| Set-Content -FilePath $FilePath -WhatIf:$WhatIf
                }
                Write-Verbose "Set header for $FilePath"            
            }
        }
        

    }

    end {

    }
}