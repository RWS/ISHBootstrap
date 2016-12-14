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

function Get-ISHOSInfo
{
    $caption=(Get-CimInstance Win32_OperatingSystem).Caption
    $regex="Microsoft Windows (?<Server>(Server) )?((?<Version>[0-9]+( R[0-9]?)?) )?(?<Type>.+)"
    $null=$caption -match $regex
    $hash=@{
        IsServer=$Matches["Server"] -ne $null
        Version=$Matches["Version"]
        Type=$Matches["Type"]
        Caption=$caption
        IsCore=-not (Test-Path "C:\Windows\explorer.exe")
    }
    New-Object -TypeName psobject -Property $hash    
}
