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

Function Get-SDLOpenSourceHeaderFormat {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    switch ([System.IO.Path]::GetExtension($FilePath))
    {
        {$_ -in '.cs'} {
            'CSharp'
            break
        }
        {$_ -in ".ps1",".psm1",".psd1"} {
            'PowerShell'
            break
        }
        Default {
            Write-Warning "Not supported extension for $_"
            break
        }
    }
}