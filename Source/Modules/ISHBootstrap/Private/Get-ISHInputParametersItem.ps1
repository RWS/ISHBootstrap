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

<#
.Synopsis
   Get the item of the ISH input parameters file
.DESCRIPTION
   Get the item of the ISH input parameters file
.EXAMPLE
   Get-ISHInputParametersItem
#>
function Get-ISHInputParametersItem {
   [CmdletBinding()]
   param (
      [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
   )

   begin {
      $ISHDeploymentNameSplat = @{}
      if ($ISHDeployment) {
         $ISHDeploymentNameSplat = @{Name = $ISHDeployment}
      }
   }

   process {
      $deployment = Get-ISHDeployment @ISHDeploymentNameSplat
      Write-Debug "deployment.Name=$($deployment.Name)"
      $regPath = "HKLM:\SOFTWARE\WOW6432Node\Trisoft\InstallTool\InfoShare\$($deployment.Name)"
      Write-Debug "Querying registrigy for regPath=$regPath"
      $folderName = Get-ItemProperty  -Path $regPath -Name Current | Select-Object -ExpandProperty Current
      Write-Debug "folderName=$folderName"

      $item = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Trisoft\InstallTool\InfoShare\$folderName\inputparameters.xml" | Get-Item
      Write-Verbose "item.Path=$($item.FullName)"
      $item
   }

   end {

   }
}
