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

function Initialize-ISHRegionalDefault
{
    # Suggested by Jered Bastinck <jbastinck@sdl.com>; Koen De Wit <kdewit@sdl.com>
    
    Write-Debug "Creating new registry drive for HKEY_USERS"
    New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS |Out-Null
    Write-Verbose "Created new registry drive for HKEY_USERS"

    # Set the regional settings
    Write-Debug "Setting Formatters for DEFAULT account"
    Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\International" -Name sShortDate -Value "dd/MM/yyyy"
    Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\International" -Name sLongDate -Value "ddddd d MMMM yyyy"
    Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\International" -Name sShortTime -Value "HH:mm:ss"
    Set-ItemProperty -Path "HKU:\.DEFAULT\Control Panel\International" -Name sLongTime -Value "HH:mm:ss"
    Write-Verbose "Set Formatters  for DEFAULT account"
}
