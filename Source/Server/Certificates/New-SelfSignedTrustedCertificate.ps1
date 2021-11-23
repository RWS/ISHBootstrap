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

param (
    [Parameter(Mandatory=$false)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null
)
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

try
{
    $block={
        # Using this provider with the self-signed certificate is very important because otherwise the .net code in ishsts cannot use to encrypt.
        # INFO http://stackoverflow.com/questions/36295461/why-does-my-private-key-not-work-to-decrypt-a-key-encrypted-by-the-public-key
        $providerName="Microsoft Strong Cryptographic Provider"
        if($PSVersionTable.PSVersion.Major -ge 5)
        {
            $certificate=New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation "cert:\LocalMachine\My" -Provider $providerName
        }
        else
        {
            # -Parameter not supported on PowerShell v4 New-SelfSignedCertificate
            $certificate=New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation "cert:\LocalMachine\My"
        }
        $rootStore = New-Object System.Security.Cryptography.X509Certificates.X509Store -ArgumentList Root, LocalMachine
        $rootStore.Open("MaxAllowed")
        $rootStore.Add($certificate)
        $rootStore.Close()

        $certificate
    }
    $blockName="Create new selfsigned certificate"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -BlockName $blockName -ScriptBlock $block
}

finally
{
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer