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
    [Parameter(Mandatory=$true,ParameterSetName="Remote")]
    [Parameter(Mandatory=$true,ParameterSetName="Local and move to remote")]
    [string]$Computer=$null,
    [Parameter(Mandatory=$false,ParameterSetName="Remote")]
    [Parameter(Mandatory=$false,ParameterSetName="Local and move to remote")]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$false,ParameterSetName="Remote")]
    [switch]$CredSSP,
    [Parameter(Mandatory=$true,ParameterSetName="Local")]
    [Parameter(Mandatory=$true,ParameterSetName="Remote")]
    [Parameter(Mandatory=$true,ParameterSetName="Local and move to remote")]
    [ValidateNotNullOrEmpty()]
    [string]$Hostname,
    [Parameter(Mandatory=$true,ParameterSetName="Local")]
    [Parameter(Mandatory=$true,ParameterSetName="Remote")]
    [Parameter(Mandatory=$true,ParameterSetName="Local and move to remote")]
    [ValidateNotNullOrEmpty()]
    [string]$CertificateAuthority,
    [Parameter(Mandatory=$false,ParameterSetName="Local")]
    [Parameter(Mandatory=$false,ParameterSetName="Remote")]
    [Parameter(Mandatory=$false,ParameterSetName="Local and move to remote")]
    [string]$OrganizationalUnit=$null,
    [Parameter(Mandatory=$false,ParameterSetName="Local")]
    [Parameter(Mandatory=$false,ParameterSetName="Remote")]
    [Parameter(Mandatory=$false,ParameterSetName="Local and move to remote")]
    [string]$Organization=$null,
    [Parameter(Mandatory=$false,ParameterSetName="Local")]
    [Parameter(Mandatory=$false,ParameterSetName="Remote")]
    [Parameter(Mandatory=$false,ParameterSetName="Local and move to remote")]
    [string]$Locality=$null,
    [Parameter(Mandatory=$false,ParameterSetName="Local")]
    [Parameter(Mandatory=$false,ParameterSetName="Remote")]
    [Parameter(Mandatory=$false,ParameterSetName="Local and move to remote")]
    [string]$State=$null,
    [Parameter(Mandatory=$false,ParameterSetName="Local")]
    [Parameter(Mandatory=$false,ParameterSetName="Remote")]
    [Parameter(Mandatory=$false,ParameterSetName="Local and move to remote")]
    [string]$Country=$null,
    [Parameter(Mandatory=$true,ParameterSetName="Local and move to remote")]
    [securestring]$PfxPassword,
    [Parameter(Mandatory=$false,ParameterSetName="Local and move to remote")]
    [switch]$MoveChain=$false
)    

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"
. "$cmdletsPaths\Helpers\Get-RandomString.ps1"

$newCertificateBlock={
    $newDomainSignedCertificateHash=@{
        Hostname=$Hostname
        CertificateAuthority=$CertificateAuthority
    }
    if($OrganizationalUnit)
    {
        $newDomainSignedCertificateHash.OrganizationalUnit=$OrganizationalUnit
    }
    if($Organization)
    {
        $newDomainSignedCertificateHash.Organization=$Organization
    }
    if($Locality)
    {
        $newDomainSignedCertificateHash.Locality=$Locality
    }
    if($State)
    {
        $newDomainSignedCertificateHash.State=$State
    }
    if($Country)
    {
        $newDomainSignedCertificateHash.Country=$Country
    }

    $certificate=New-DomainSignedCertificate @newDomainSignedCertificateHash
    Write-Verbose "Installed new certificate with friendly name $($certificate.FriendlyName)"
    $certificate
}


try
{
    $blockName="Issuing certificate"
    Write-Progress @scriptProgress -Status $blockName
    $hash=@{
        ScriptBlock=$newCertificateBlock
        BlockName=$blockName
    }

    if($PSCmdlet.ParameterSetName -eq "Remote")
    {
        $hash.UseParameters=@("Hostname","CertificateAuthority","OrganizationalUnit","Organization","Locality","State","Country")
        if($CredSSP)
        {
            $session=New-PSSession -ComputerName $Computer -Credential $Credential -UseSSL -Authentication Credssp
            $certificate=Invoke-CommandWrap -Session $session @hash
        }
        else
        {
            $certificate=Invoke-CommandWrap -ComputerName $Computer -Credential $Credential @hash
        }
    }
    else
    {
        $certificate=Invoke-CommandWrap @hash
    }
    if($PSCmdlet.ParameterSetName -eq "Local and move to remote")
    {
        Write-Progress @scriptProgress -Status "Moving certificate to $Computer"
        $certificate|Move-CertificateToRemote -ComputerName $Computer -PfxPassword $PfxPassword -MoveChain:$MoveChain
        $certificate=$certificate|Add-Member -NotePropertyName PSComputerName -NotePropertyValue $Computer -PassThru
    }
    $certificate
}
catch
{
    Write-Error $_
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
