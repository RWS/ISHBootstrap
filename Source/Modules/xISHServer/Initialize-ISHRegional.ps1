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

function Initialize-ISHRegional
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-4D619D1F-CA8C-4E43-BA0C-8CEB456AC263
    
    # Set the regional settings
    Write-Debug "Setting UI Language override to en-US"
    Set-WinUILanguageOverride en-US
    Write-Verbose "Set UI Language override to en-US"

    Write-Debug "Setting Formatters"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortDate -Value "dd/MM/yyyy"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sLongDate -Value "ddddd d MMMM yyyy"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortTime -Value "HH:mm:ss"
    Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sLongTime -Value "HH:mm:ss"
    Write-Verbose "Set Formatters"
}
