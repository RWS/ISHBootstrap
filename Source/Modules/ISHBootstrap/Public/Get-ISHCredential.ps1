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
    Return corresponding credentials
.DESCRIPTION
    This cmdlet helper returns PSCredential object based on input parameter.
    Corresponding username and password will be taken from deployment parameters.
.PARAMETER ServiceUser
    Get servece user credentials from deployment parameters. See Get-ISHDeploymentParameters
.PARAMETER ServiceAdmin
    Get admin user credentials from deployment configuration.
.PARAMETER ISHDeployment
    Specifies the name or instance of the Content Manager deployment. See Get-ISHDeployment for more details.
.EXAMPLE
    Get-ISHCredential -ServiceUser
.EXAMPLE
    Get-ISHCredential -ServiceAdmin -ISHDeployment InfoShareInstanceN
#>
Function Get-ISHCredential {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "ServiceUser")]
        [switch]$ServiceUser,
        [parameter(Mandatory = $true, ParameterSetName = "ServiceAdmin")]
        [switch]$ServiceAdmin,
        [parameter(Mandatory = $false, ParameterSetName = "ServiceUser")]
        [parameter(Mandatory = $false, ParameterSetName = "ServiceAdmin")]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ServiceUser' {
                $deploymentParameters = Get-ISHDeploymentParameters -ShowPassword @ISHDeploymentSplat
                New-PSCredential `
                -Username ($deploymentParameters | Where-Object -Property Name -Like 'serviceusername').Value `
                -Password ($deploymentParameters | Where-Object -Property Name -Like 'servicepassword').Value
            }
            'ServiceAdmin' {
                $coreConfiguration = Get-ISHCoreConfiguration @ISHDeploymentSplat
                if ($coreConfiguration.ServiceAdmin) {
                    $coreConfiguration.ServiceAdmin.Credential
                }
            }
        }

    }

    end {

    }
}
