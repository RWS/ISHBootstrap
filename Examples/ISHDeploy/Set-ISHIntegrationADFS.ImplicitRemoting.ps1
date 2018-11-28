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

param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$true)]
    [string]$ISHVersion,
    [Parameter(Mandatory=$false)]
    [switch]$IncludeInternalClients=$false
)        
$ishBootStrapRootPath=Resolve-Path "$PSScriptRoot\..\.."
$cmdletsPaths="$ishBootStrapRootPath\Source\Cmdlets"
$serverScriptsPaths="$ishBootStrapRootPath\Source\Server"

. $ishBootStrapRootPath\Examples\Cmdlets\Get-ISHBootstrapperContextValue.ps1
. $ishBootStrapRootPath\Examples\ISHDeploy\Cmdlets\Write-Separator.ps1
Write-Separator -Invocation $MyInvocation -Header -Name "Configure"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

if(-not $Computer)
{
    & "$serverScriptsPaths\Helpers\Test-Administrator.ps1"
}

. $cmdletsPaths\Helpers\Add-ModuleFromRemote.ps1
. $cmdletsPaths\Helpers\Remove-ModuleFromRemote.ps1

try
{
    #region adfs information
    $adfsComputerName=Get-ISHBootstrapperContextValue -ValuePath "Configuration.ADFSComputerName"
    #endegion

	$ishServerVersion=($ishVersion -split "\.")[0]

    Write-Progress @scriptProgress -Status "Getting information from ADFS"

    if($Computer)
    {
        $ishDelpoyModuleName="ISHDeploy.$($ishServerVersion).0"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Credential $Credential -Name $ishDelpoyModuleName
    }
    $remoteADFS=Add-ModuleFromRemote -ComputerName $adfsComputerName -Name ADFS

    #region query properties from adfs
    $properties=Get-ADFSProperties
    $primaryTokenSigningCertificate=Get-AdfsCertificate -CertificateType Token-Signing|Where-Object -Property IsPrimary -EQ $true
    $endpoints=Get-AdfsEndpoint

    #Issuer name
    $issuerName="$($primaryTokenSigningCertificate.Certificate.NotBefore.ToString("yyyyMMdd"")).$($properties.HostName).ADFS"
    #WS Federation endpoint
    $wsFederationUri=($endpoints | Where-Object -Property Protocol -EQ "SAML 2.0/WS-Federation").FullUrl.AbsoluteUri
    #WS Trust endpoint
    $wsTrustUri=($endpoints | Where-Object -Property Protocol -EQ WS-Trust | Where-Object -Property Version -EQ wstrust13 |Where-Object -Property AddressPath -Like "*windowsmixed").FullUrl.AbsoluteUri
    #WS Trust metadata exchange endpoint
    $wsTrustMexUri=($endpoints | Where-Object -Property Protocol -EQ WS-Mex).FullUrl.AbsoluteUri
    #The authentication type
    $bindingType="WindowsMixed"
    #Token signing thumbprint
    $tokenSigningCertificateThumbprint=$primaryTokenSigningCertificate.Thumbprint
    $issuercertificatevalidationmode = "None"

    #endregion

    #region Configure ADFS integration
    Write-Progress @scriptProgress -Status "Integrating ADFS on $DeploymentName"

    # Set WS Federation integration
    Set-ISHIntegrationSTSWSFederation -ISHDeployment $DeploymentName -Endpoint $wsFederationUri
    # Set WS Trust integration
    if($includeInternalClients)
    {
        Set-ISHIntegrationSTSWSTrust -ISHDeployment $DeploymentName -Endpoint $wsTrustUri -MexEndpoint $wsTrustMexUri -BindingType $bindingType -IncludeInternalClients
    }
    else
    {
        Set-ISHIntegrationSTSWSTrust -ISHDeployment $DeploymentName -Endpoint $wsTrustUri -MexEndpoint $wsTrustMexUri -BindingType $bindingType
    }
    # Set Token signing certificate
    Set-ISHIntegrationSTSCertificate -ISHDeployment $DeploymentName -Issuer $issuerName -Thumbprint $tokenSigningCertificateThumbprint -ValidationMode $issuercertificatevalidationmode
    #endregion

}
finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
    Remove-ModuleFromRemote -Remote $remoteADFS
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer -Name "Configure"