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

function Grant-ISHUserLogOnAsService{
param(
    [string[]] $User
    )
    $tempExportInfPath=Join-Path $env:TEMP tempexport.inf
    $tempSECEditPath=Join-Path $env:TEMP secedit.sdb
    $tempExportInfPath=Join-Path $env:TEMP tempexport.inf
    if(Test-Path $tempExportInfPath)
    {
        Write-Warning "Removing $tempExportInfPath"
        Remove-Item -Path $tempExportInfPath -Force
    } 
    if(Test-Path $tempSECEditPath)
    {
        Write-Warning "Removing $tempSECEditPath"
        Remove-Item -Path $tempSECEditPath -Force
    } 
    #Get list of currently used SIDs 
    & secedit /export /cfg $tempExportInfPath 
    $curSIDs = Select-String $tempExportInfPath -Pattern "SeServiceLogonRight" 
    $Sids = $curSIDs.line 
    $sidstring = ""
    foreach($user in $User){
        $objUser = New-Object System.Security.Principal.NTAccount($user)
        $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
        if(!$Sids.Contains($strSID) -and !$sids.Contains($user)){
            $sidstring += ",*$strSID"
        }
    }
    if($sidstring){
        $newSids = $sids + $sidstring
        Write-Host "New Sids: $newSids"
        $tempinf = Get-Content $tempExportInfPath
        $tempinf = $tempinf.Replace($Sids,$newSids)
        Add-Content -Path $tempExportInfPath -Value $tempinf
        & secedit /import /db secedit.sdb /cfg $tempExportInfPath 
        & secedit /configure /db secedit.sdb 
 
        & gpupdate /force 
    }
    else{
        Write-Host "No new sids"
    }

    
 
    Remove-Item $tempSECEditPath -force -ErrorAction SilentlyContinue
    Remove-Item $tempExportInfPath -force -ErrorAction SilentlyContinue

}
