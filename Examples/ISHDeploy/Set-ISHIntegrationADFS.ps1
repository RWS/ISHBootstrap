param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$false)]
    [switch]$IncludeInternalClients=$false
)        
$ishBootStrapRootPath=Resolve-Path "$PSScriptRoot\..\.."
$cmdletsPaths="$ishBootStrapRootPath\Source\Cmdlets"
$scriptsPaths="$ishBootStrapRootPath\Source\Scripts"

. $ishBootStrapRootPath\Examples\Cmdlets\Get-ISHBootstrapperContextValue.ps1
. $ishBootStrapRootPath\Examples\ISHDeploy\Cmdlets\Write-Separator.ps1
Write-Separator -Invocation $MyInvocation -Header -Name "Configure"

if(-not $Computer)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

if(-not (Get-Command Invoke-CommandWrap -ErrorAction SilentlyContinue))
{
    . $cmdletsPaths\Helpers\Invoke-CommandWrap.ps1
}  

#region adfs information
$adfsComputerName=Get-ISHBootstrapperContextValue -ValuePath "Configuration.ADFSComputerName"
#endegion

$getADFSInformationBlock = {
    $hash=@{}
    $properties=Get-ADFSProperties
    $hash["HostName"]=$properties.HostName
    $hash["TokenSigningCertificate"]=@()
    $tokenSigningCertificate=Get-AdfsCertificate -CertificateType Token-Signing
    $tokenSigningCertificate | ForEach-Object {
        $hash["TokenSigningCertificate"]+=New-Object PSObject -Property @{
            Thumbprint=$_.Thumbprint
            IssuedOn=$_.Certificate.NotBefore.ToString("yyyyMMdd")
            IsPrimary=$_.IsPrimary
        }
    }
    $endpoints=Get-AdfsEndpoint
    $hash["WSMex"] = ($endpoints | Where-Object -Property Protocol -EQ WS-Mex).FullUrl.AbsoluteUri
    $hash["WSFederation"] = ($endpoints | Where-Object -Property Protocol -EQ "SAML 2.0/WS-Federation").FullUrl.AbsoluteUri
    $hash["WSTrust"] = ($endpoints | Where-Object -Property Protocol -EQ WS-Trust | Where-Object -Property Version -EQ wstrust13 |Where-Object -Property AddressPath -Like "*windowsmixed").FullUrl.AbsoluteUri

    New-Object PSObject -Property $hash
}

$integrationBlock= {
    $deployment= Get-ISHDeployment -Name $DeploymentName

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
}


try
{
    $adfsInformation=Invoke-CommandWrap -ComputerName $adfsComputerName -ScriptBlock $getADFSInformationBlock -BlockName "Get ADFS information"
    $primaryTokenSigningCertificate=$adfsInformation.TokenSigningCertificate|Where-Object -Property IsPrimary -EQ $true

    #Issuer name
    $issuerName="$($primaryTokenSigningCertificate.IssuedOn).$($adfsInformation.HostName).ADFS"
    #WS Federation endpoint
    $wsFederationUri=$adfsInformation.WSFederation
    #WS Trust endpoint
    $wsTrustUri=$adfsInformation.WSTrust
    #WS Trust metadata exchange endpoint
    $wsTrustMexUri=$adfsInformation.WSMex
    #The authentication type
    $bindingType="WindowsMixed"
    #Token signing thumbprint
    $tokenSigningCertificateThumbprint=$primaryTokenSigningCertificate.Thumbprint
    $issuercertificatevalidationmode = "None"

    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $integrationBlock -BlockName "Integrate ADFS on $DeploymentName" -UseParameters @("DeploymentName","issuerName","wsFederationUri","wsTrustUri","wsTrustMexUri","bindingType","tokenSigningCertificateThumbprint","issuercertificatevalidationmode","includeInternalClients")
}
finally
{

}

Write-Separator -Invocation $MyInvocation -Footer -Name "Configure"