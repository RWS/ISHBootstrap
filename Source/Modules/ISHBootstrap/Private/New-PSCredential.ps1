<#
# Copyright (c) 2021 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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
   Create new PSCredential
.DESCRIPTION
   Create new PSCredential from username and non-secure password
.EXAMPLE
   New-PSCredential -Username username -Password password
#>
function New-PSCredential {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [string]$Username,
      [Parameter(Mandatory = $true)]
      [string]$Password
   )

   begin {
      Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
      foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
   }

   process {
      Write-Debug "Username=$Username"
      $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
      New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
   }

   end {

   }
}
