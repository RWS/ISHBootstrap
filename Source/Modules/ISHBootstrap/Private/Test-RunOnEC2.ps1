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
    Test if the system is Run on EC2
.DESCRIPTION
    Test if the system is Run on EC2
.EXAMPLE
    Test-RunOnEC2
#>
function Test-RunOnEC2 {
    [OutputType([Boolean])]
    [CmdletBinding()]
    param (
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        <#  Conditions of being on Run on EC2
            ISH.AMI Marker  was set by Packer
            AWSPowerShell module is installed
            EC2 metadata is reachable
        #>
        
        if (Test-ISHMarker -Name ISH.AMI) {
            try {
                $ec2MetadataPointReachable = $null -ne (Get-EC2InstanceMetadata -Category AmiId)

                Write-Debug "ec2MetadataPointReachable=$ec2MetadataPointReachable"

                if ($ec2MetadataPointReachable) {
                    if (Get-TagEC2 | Where-Object -Property Name -EQ 'ISHStackConfiguration') {
                        return $true
                    }
                }
            }
            catch {
                return $false
            }
        }
        return $false
    }

    end {

    }
}
