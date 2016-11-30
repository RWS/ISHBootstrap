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

function Initialize-ISHMSDTCTransactionTimeout
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-BD82DCF1-B23C-4877-892B-DCC9FC1F0926
    # http://stackoverflow.com/questions/20791497/use-powershell-to-set-component-services-transaction-timeout
    Write-Debug "Setting MSDTC Transaction Timeout to 3600"
    $comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
    $LocalColl = $comAdmin.Connect("localhost")
    $LocalComputer = $LocalColl.GetCollection("LocalComputer",$LocalColl.Name)
    $LocalComputer.Populate()

    $LocalComputerItem = $LocalComputer.Item(0)
    $CurrVal = $LocalComputerItem.Value("TransactionTimeout")

    $LocalComputerItem.Value("TransactionTimeout") = 3600
    $LocalComputer.SaveChanges()|Out-Null
    $newTimeout=$LocalComputerItem.Value("TransactionTimeout")
    Write-Verbose "Set MSDTC Transaction Timeout to $newTimeout"
}
