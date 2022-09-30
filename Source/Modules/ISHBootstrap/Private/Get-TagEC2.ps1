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
   Get the tags configured on the current EC2 instance
.DESCRIPTION
   With the assumption that the operating system is hosted on AWS EC2, get the tags configured on the EC2 instance
.EXAMPLE
   Get-TagEC2
#>
function Get-TagEC2 {
    [CmdletBinding()]
    param (
    )

    begin {
    }

    process {
        Write-Debug "Querying the metada endpoint"
        $instanceId = Get-EC2InstanceMetadata -Category InstanceId
        Write-Debug "instanceId=$instanceId"
        $tag = Get-EC2Tag -Filter @{Name = "resource-id";Value=$instanceId} | Select-Object @{Name = "Name"; Expression = { $_.Key } }, Value

        $tag
    }

    end {
    }
}
