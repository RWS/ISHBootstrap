param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$false)]
    [switch]$IncludeInternalClients=$false
)        
. $PSScriptRoot\Cmdlets\Write-Separator.ps1
Write-Separator -Invocation $MyInvocation -Header

$ishBootStrapRootPath=Resolve-Path "$PSScriptRoot\..\.."
$cmdletsPaths="$ishBootStrapRootPath\Source\Cmdlets"
$scriptsPaths="$ishBootStrapRootPath\Source\Scripts"

if(-not $Computer)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

if(-not (Get-Command Invoke-CommandWrap -ErrorAction SilentlyContinue))
{
    . $cmdletsPaths\Helpers\Invoke-CommandWrap.ps1
}  

#region adfs information
$adfsComputerName="adfs.example.com"
#endegion

#region integraion filename
$adfsIntegrationISHFilename="$(Get-Date -Format "yyyyMMdd").ADFSIntegrationISH.zip"

#endregion

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

    Save-ISHIntegrationSTSConfigurationPackage -ISHDeployment $DeploymentName -FileName $adfsIntegrationISHFilename -ADFS

    Get-ISHPackageFolderPath -ISHDeployment $DeploymentName -UNC
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

    $uncPath=Invoke-CommandWrap -ComputerName $Computer -ScriptBlock $integrationBlock -BlockName "Integrate With ADFS for $DeploymentName" -UseParameters @("DeploymentName","issuerName","wsFederationUri","wsTrustUri","wsTrustMexUri","bindingType","tokenSigningCertificateThumbprint","issuercertificatevalidationmode","includeInternalClients","adfsIntegrationISHFilename")

    $sourceUncZipPath=Join-Path $uncPath $adfsIntegrationISHFilename
    $tempZipPath=Join-Path $env:TEMP $adfsIntegrationISHFilename
    Write-Debug "Downloading file from $sourceUncZipPath"
    Copy-Item -Path $sourceUncZipPath -Destination $env:TEMP -Force
    if(-not (Test-Path $tempZipPath))
    {
        throw "Cannot find file $tempZipPath"
    }
    Write-Verbose "Downloaded file to $tempZipPath"

    $expandPath=Join-Path $env:TEMP ($adfsIntegrationISHFilename.Replace(".zip",""))
    if(Test-Path ($expandPath))
    {
        Write-Warning "$expandPath exists. Removing"
        Remove-Item $expandPath -Force -Recurse | Out-Null
    }

    New-Item -Path $expandPath -ItemType Directory|Out-Null

    Write-Debug "Expanding $tempZipPath to $expandPath"
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')|Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempZipPath, $expandPath)|Out-Null
    Write-Verbose "Expanded $tempZipPath to $expandPath"

    $scriptADFSIntegrationISHPath=Join-Path $expandPath "Invoke-ADFSIntegrationISH.ps1"

    Write-Verbose "Configurating rellying parties on $adfsComputerName"
    & $scriptADFSIntegrationISHPath -Computer $adfsComputerName -Action Set -Verbose
    Write-Host "Configured rellying parties on $adfsComputerName"

}
finally
{

}

Write-Separator -Invocation $MyInvocation -Footer