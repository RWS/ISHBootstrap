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

function Initialize-ISHMSDTCSettings
{
    Write-Debug "Setting DTC Settings"

    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC -Name AllowOnlySecureRpcCalls -Value 0 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC -Name TurnOffRpcSecurity -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name NetworkDtcAccess -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name XaTransactions -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name NetworkDtcAccessTransactions -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name NetworkDtcAccessOutbound -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name NetworkDtcAccessInbound -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name LuTransactions -Value 1 -Type DWord
    Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\MSDTC\Security -Name LuTransactions -Value 1 -Type DWord

    Write-Verbose "Set MSDTC Settings"

}
