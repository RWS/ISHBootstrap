param (
    [Parameter(Mandatory=$false)]
    [string]$Computer,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName,
    [Parameter(Mandatory=$true)]
    [string]$ISHVersion    
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
else
{
   . $cmdletsPaths\Helpers\Add-ModuleFromRemote.ps1
   . $cmdletsPaths\Helpers\Remove-ModuleFromRemote.ps1
}

try
{
    if($Computer)
    {
        $ishDelpoyModuleName="ISHDeploy.$ISHVersion"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Name $ishDelpoyModuleName
    }

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
        UserRole=@("Administrator","Author")
    }
    Set-ISHUIEventMonitorTab -ISHDeployment $DeploymentName @hash
    Move-ISHUIEventMonitorTab -ISHDeployment $DeploymentName -Label $hash["Label"] -First
    Write-Host "Event monitor tab created"

}
finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
}

Write-Separator -Invocation $MyInvocation -Footer