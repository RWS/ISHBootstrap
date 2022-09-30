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
   Check if a certificate is trusted. If not, add it to TrustedPublisher
.DESCRIPTION
   Check if a certificate is trusted. If not, add it to TrustedPublisher
.EXAMPLE
   Set-CertificateTrusted -Thumbprint thumbprint
#>
function Set-CertificateTrusted {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Thumbprint
    )
    $personalStore = New-Object System.Security.Cryptography.X509Certificates.X509Store "My", "LocalMachine"
    $personalStore.Open("ReadOnly")
    $isTrusted = $personalStore.Certificates.Find("FindByThumbprint", $Thumbprint, $true)
	if (-not $isTrusted.Count) {
        Write-Verbose "Certificate $Thumbprint is not trusted. Adding to TrustedPublisher"
        $cert = Get-ChildItem "Certificate::LocalMachine\My\$Thumbprint"
        $TrustedStore = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root", "LocalMachine"
        $TrustedStore.Open("ReadWrite")
        $TrustedStore.Add($cert)
        $TrustedStore.Close()
    }
    else{
        Write-Verbose "Certificate $Thumbprint is valid"
    }
}