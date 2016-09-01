param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$true)]
    [string]$ISHVersion,
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

. $cmdletsPaths\Helpers\Add-ModuleFromRemote.ps1
. $cmdletsPaths\Helpers\Remove-ModuleFromRemote.ps1

try
{
    #region adfs information
    $adfsComputerName="adfs.example.com"
    #endegion

    #region integraion filename
    $adfsIntegrationISHFilename="$(Get-Date -Format "yyyyMMdd").ADFSIntegrationISH.zip"

    #endregion

    if($Computer)
    {
        $ishDelpoyModuleName="ISHDeploy.$ISHVersion"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Name $ishDelpoyModuleName
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

    #region Retrieve integration package
    Save-ISHIntegrationSTSConfigurationPackage -ISHDeployment $DeploymentName -FileName $adfsIntegrationISHFilename -ADFS

    $uncPath=Get-ISHPackageFolderPath -ISHDeployment $DeploymentName -UNC

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
    #endregion

    #region Execute integration script
    Write-Verbose "Configurating rellying parties on $adfsComputerName"
    & $scriptADFSIntegrationISHPath -Computer $adfsComputerName -Action Set -Verbose
    Write-Host "Configured rellying parties on $adfsComputerName"
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

Write-Separator -Invocation $MyInvocation -Footer