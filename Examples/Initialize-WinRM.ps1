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

if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

try
{
    $sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
    $cmdletsPaths="$sourcePath\Cmdlets"
    $serverScriptsPaths="$sourcePath\Server"

    . "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
    $computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null

    if(-not $computerName)
    {
        Write-Error "This script works only against a remote server"
        & "$serverScriptsPaths\Helpers\Test-Administrator.ps1"
    }
    
    & $serverScriptsPaths\WinRM\Install-WinRMPrerequisites.ps1 -Computer $computerName -Credential $credential

    $winRMCredSSP=Get-ISHBootstrapperContextValue -ValuePath "WinRMCredSSP"
    if($winRMCredSSP.UseWebCertificate)
    {
        Write-Verbose "Using web certificate for WinRM"
        $winRMCertificate=Get-ISHBootstrapperContextValue -ValuePath "WebCertificate"
    }
    else
    {
        $winRMCertificate=$winRMCredSSP.Certificate
    }
    $hash=@{
        CertificateAuthority=$winRMCertificate.Authority
    }
    if($computerName)
    {
        $hash.Hostname=[System.Net.Dns]::GetHostByName($computerName)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() }
    }
    else
    {
        $hash.Hostname=[System.Net.Dns]::GetHostByName($env:COMPUTERNAME)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() }
    }
    if($winRMCertificate.OrganizationalUnit)
    {
        $hash.OrganizationalUnit=$winRMCertificate.OrganizationalUnit
    }
    if($winRMCertificate.Organization)
    {
        $hash.Organization=$winRMCertificate.Organization
    }
    if($winRMCertificate.Locality)
    {
        $hash.Locality=$winRMCertificate.Locality
    }
    if($winRMCertificate.State)
    {
        $hash.State=$winRMCertificate.State
    }
    if($winRMCertificate.Country)
    {
        $hash.Country=$winRMCertificate.Country
    }
    
    if($computerName)
    {
        if($winRMCredSSP.MoveChain)
        {
            $hash.MoveChain=$winRMCredSSP.MoveChain
        }
        if($winRMCredSSP.PfxPassword)
        {
            $hash.PfxPassword=ConvertTo-SecureString $winRMCredSSP.PfxPassword -AsPlainText -Force
        }
        elseif($winRMCredSSP.PfxPasswordExpression)
        {
            $hash.PfxPassword=Invoke-Expression $winRMCredSSP.PfxPasswordExpression
        }
        else
        {
            throw "PfxPassword or PfxPasswordExpression must be defined within winRMCredSSP"
        }
    }

    if($computerName)
    {
        $certificate=& $serverScriptsPaths\Certificates\Install-Certificate.ps1 -Computer $computerName -Credential $credential @hash
    }
    else
    {
        $certificate=& $serverScriptsPaths\Certificates\Install-Certificate.ps1 @hash
    }

    & $serverScriptsPaths\WinRM\Enable-WSManCredSSP.ps1 -Computer $computerName -Credential $credential -Thumbprint $certificate.Thumbprint

}
finally
{
}