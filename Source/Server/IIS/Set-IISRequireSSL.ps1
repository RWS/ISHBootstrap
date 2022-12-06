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

param (
    [Parameter(Mandatory=$false)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null
)
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

try
{
    $block={
        $locations=@()
        Get-ISHDeployment | ForEach-Object {
            $deployment=$_

            if($deployment.SoftwareVersion.Major -eq 12)
            {
                #required only for 12.0.* deployments
                $locations+="$($deployment.WebSiteName)/$($deployment.WebAppNameCM)"
                $locations+="$($deployment.WebSiteName)/$($deployment.WebAppNameSTS)"
            }
            else
            {
                
            }
        }
        foreach($location in $locations)
        {
            Set-WebConfiguration -Location $location -Filter 'system.webserver/security/access' -Value "Ssl"
        }

    }
    
    $blockName="Configure IIS Application RequireSSL"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -BlockName $blockName -ScriptBlock $block
}

finally
{
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
