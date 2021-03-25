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
   Get the credentials
.DESCRIPTION
   Get the credentials from deployment parameters
.EXAMPLE
   Get-ISHCredential -ServiceUser
.EXAMPLE
   Get-ISHCredential -ServiceAdmin
#>
Function Get-ISHCredential {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "ServiceUser")]
        [switch]$ServiceUser,
        [parameter(Mandatory = $true, ParameterSetName = "ServiceAdmin")]
        [switch]$ServiceAdmin
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $deploymentParameters = Get-ISHDeploymentParameters -ShowPassword
        switch ($PSCmdlet.ParameterSetName) {
            'ServiceUser' {
                New-PSCredential
                -Username ($deploymentParameters | Where-Object -Property Name -Like 'serviceusername').Value
                -Password ($deploymentParameters | Where-Object -Property Name -Like 'servicepassword').Value
            }
            'ServiceAdmin' {
                # TODO: Get actual credential from ISHDeploymentParameters which are not there at this moment.
                if ($deploymentParameters | Where-Object -Property Name -Like 'adminusername') {
                    New-PSCredential
                    -Username ($deploymentParameters | Where-Object -Property Name -Like 'adminusername').Value
                    -Password ($deploymentParameters | Where-Object -Property Name -Like 'adminpassword').Value
                }
                else {
                    New-PSCredential -Username 'admin' -Password 'admin'
                }
            }
        }

    }

    end {

    }
}
