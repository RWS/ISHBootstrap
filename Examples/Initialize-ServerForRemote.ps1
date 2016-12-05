<#
# Copyright (c) 2014 All Rights Reserved by the SDL Group.
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
    $scriptsPaths="$sourcePath\Scripts"

    . "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
    $computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null

    if(-not $computerName)
    {
        Write-Error "This script works only against a remote server"
    }
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"

    & $scriptsPaths\WinRM\Install-WinRMPrerequisites.ps1 -Computer $computerName -Credential $credential

    $winRmCertificate=Get-ISHBootstrapperContextValue -ValuePath "WinRMCertificate"
    $hash=@{
        CertificateAuthority=$winRmCertificate.Authority
    }
    if($winRmCertificate.OrganizationalUnit)
    {
        $hash.OrganizationalUnit=$winRmCertificate.OrganizationalUnit
    }
    if($winRmCertificate.Organization)
    {
        $hash.Organization=$winRmCertificate.Organization
    }
    if($winRmCertificate.Locality)
    {
        $hash.Locality=$winRmCertificate.Locality
    }
    if($winRmCertificate.State)
    {
        $hash.State=$winRmCertificate.State
    }
    if($winRmCertificate.Country)
    {
        $hash.Country=$winRmCertificate.Country
    }
    if($winRmCertificate.MoveChain)
    {
        $hash.MoveChain=$winRmCertificate.MoveChain
    }
    if($winRmCertificate.PfxPassword)
    {
        $hash.PfxPassword=ConvertTo-SecureString $WinRMCertificate.PfxPassword -AsPlainText -Force
    }
    elseif($winRmCertificate.PfxPasswordExpression)
    {
        $hash.PfxPassword=Invoke-Expression $WinRMCertificate.PfxPasswordExpression
    }
    else
    {
        throw "PfxPassword or PfxPasswordExpression must be defined within WinRMCertificate"
    }

    & $scriptsPaths\WinRM\Enable-WSManCredSSP.ps1 -Computer $computerName -Credential $credential @hash
}
finally
{
}