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
   Creates a new ISHRemote session for the ISHWS web services
.DESCRIPTION
   Creates a new ISHRemote session for the ISHWS web services.
.EXAMPLE
   New-ISHWSSession -Credential $credential
.EXAMPLE
   New-ISHWSSession -ServiceAdmin

#>
Function New-ISHWSSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Custom credential")]
        [pscredential]$Credential,
        [Parameter(Mandatory = $true, ParameterSetName = "Service administrator credential")]
        [switch]$ServiceAdmin
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        # extract information from the deployment
        Write-Debug "Loading information from the deployment"
        $deployment = Get-ISHDeployment
        $ishWSUrl = "https://localhost/$($deployment.WebAppNameWS)/"
        Write-Debug "ishWSUrl=$ishWSUrl"
        $ishSTSUrl = "https://localhost/$($deployment.WebAppNameSTS)"
        Write-Debug "ishSTSUrl=$ishSTSUrl"
        $ishSTSIssuerUrl = $ishSTSUrl + "/issue/wstrust/mixed/username"
        Write-Debug "ishSTSIssuerUrl=$ishSTSIssuerUrl"
        $ishSTSIssuerMexUrl = $ishSTSUrl + "/issue/wstrust/mex"
        Write-Debug "ishSTSIssuerMexUrl=$ishSTSIssuerMexUrl"

        # initialize the credentials to use for authentication
        switch ($PSCmdlet.ParameterSetName) {
            'Custom credential' {

            }
            'Service administrator credential' {
                Write-Debug "Getting credentials for the ServiceAdmin"
                $Credential = Get-ISHCredential -ServiceAdmin
            }
        }

        $newIshSessionSplat = @{
            WsBaseUrl           = $ishWSUrl
            WsTrustIssuerUrl    = $ishSTSIssuerUrl
            WsTrustIssuerMexUrl = $ishSTSIssuerMexUrl
            PSCredential        = $Credential
        }

        New-IshSession @newIshSessionSplat -IgnoreSslPolicyErrors

    }

    end {

    }
}
