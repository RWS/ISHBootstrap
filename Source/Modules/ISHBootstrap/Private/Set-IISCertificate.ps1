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
   Set the thumbprint on the IIS Default Website https binding
.DESCRIPTION
   Set the thumbprint on the IIS Default Website https binding
.EXAMPLE
   Set-IISThumbprint -Thumbprint thumbprint
.NOTES
   IIS:\ paths require the WebAdministration module to be loaded
#>
Function Set-IISCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Thumbprint
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach($psbp in $PSBoundParameters.GetEnumerator()){Write-Debug "$($psbp.Key)=$($psbp.Value)"}
    }

    process {
        $module = Get-Module -Name WebAdministration -ErrorAction SilentlyContinue
        if (-not $module) {
            Import-Module -Name WebAdministration -Global
        }
        Get-Item -Path "Cert:\LocalMachine\My\$Thumbprint" | Set-Item -Path "IIS:\SslBindings\0.0.0.0!443"
    }

    end {

    }
}
