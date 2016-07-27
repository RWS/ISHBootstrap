param (
    [Parameter(Mandatory=$false)]
    [string]$Computer,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$true)]
    [string]$ISHVersion    
)
$ishBootStrapRootPath="C:\GitHub\ISHBootstrap"
$cmdletsPaths="$ishBootStrapRootPath\Source\Cmdlets"
$scriptsPaths="$ishBootStrapRootPath\Source\Scripts"

if(-not $Computer)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

if(-not (Get-Command Invoke-ImplicitRemoting -ErrorAction SilentlyContinue))
{
    . $cmdletsPaths\Helpers\Invoke-ImplicitRemoting.ps1
}        



$setUIFeaturesScirptBlock= {

    #region xopus information
    #XOPUS License Key
    $xopusLicenseKey = "license"
    $xopusLicenseDomain= "ish.example.com"

    $externalId="ExternalUser"
    #endegion

    # Set the license and enable the Content Editor
    Set-ISHContentEditor -ISHDeployment $DeploymentName -LicenseKey "$xopusLicenseKey" -Domain $xopusLicenseDomain
    Enable-ISHUIContentEditor -ISHDeployment $DeploymentName
    Write-Host "Content editor enabled and licensed"

    # Enable the Quality Assistant
    Enable-ISHUIQualityAssistant -ISHDeployment $DeploymentName
    Write-Host "Quality assistant enabled"

    # Enable the External Preview using externalid
    Enable-ISHExternalPreview -ISHDeployment $DeploymentName -ExternalId $externalId
    Write-Host "External preview enabled"

    # Create a new tab for CUSTOM event types
    $hash=@{
        Label="Custom Event"
        Description="Show all custom events"
        EventTypesFilter=@("CUSTOM1","CUSTOM2")
    }
    Set-ISHUIEventMonitorTab -ISHDeployment $DeploymentName @hash
    Move-ISHUIEventMonitorTab -ISHDeployment $DeploymentName -Label $hash["Label"] -First
    Write-Host "Event monitor tab created"
}


try
{
    $ishDelpoyModuleName="ISHDeploy.$ishVersion"
    Invoke-ImplicitRemoting -ScriptBlock $setUIFeaturesScirptBlock -BlockName "Set UI Features on $DeploymentName" -ComputerName $Computer -ImportModule $ishDelpoyModuleName
}
finally
{

}
