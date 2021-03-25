<#
# Copyright (c) 2021 All Rights Reserved by the SDL Group.
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
   Set the tag for EC2 instance
.DESCRIPTION
   With the assumption that the operating system is hosted on AWS EC2, set the tag for EC2 instance
.EXAMPLE
   Set-TagEC2 -Name name
.EXAMPLE
   Set-TagEC2 -Name name -Value value
#>
function Set-TagEC2 {
   [CmdletBinding()]
   param (
      [Parameter(Mandatory = $true)]
      [string]$Name,
      [Parameter(Mandatory = $false)]
      $Value = $null
   )

   begin {
   }

   process {
      Write-Debug "Querying the metada endpoint"
      $instanceId = Get-EC2InstanceMetadata -Category InstanceId
      Write-Debug "instanceId=$instanceId"

      $tag = New-Object Amazon.EC2.Model.Tag
      $tag.Key = $Name
      $tag.Value = $Value
      Write-Debug "Tag=$tag"

      New-EC2Tag -Resource $instanceId -Tag $tag
   }

   end {

   }
}
