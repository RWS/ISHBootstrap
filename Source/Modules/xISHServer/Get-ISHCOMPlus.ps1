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

function Get-ISHCOMPlus
{
    $comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
    $Catalog = New-Object -com COMAdmin.COMAdminCatalog 
    $oapplications = $catalog.getcollection("Applications") 
    $oapplications.populate()
    foreach ($oapplication in $oapplications){ 
        $hash=[ordered]@{
            Name=$oapplication.Name
            IsValid=[bool]($oapplication.Valid)
            IsEnabled=[bool]($oapplication.Value("IsEnabled"))
        }

        $skeyappli = $oapplication.key 
        $oappliInstances = $oapplications.getcollection("ApplicationInstances",$skeyappli) 
        $oappliInstances.populate() 
        $hash.IsRunning=$oappliInstances.count -gt 0

        New-Object -TypeName PSObject -Property $hash
    }
}
