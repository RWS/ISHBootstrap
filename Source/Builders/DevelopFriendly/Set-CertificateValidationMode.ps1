
param(
    [Parameter(Mandatory = $false)]
    [string]$certificateValidationMode = "None"

)


$cmdletsPaths = "$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"

Write-Separator -Invocation $MyInvocation -Header
$scriptProgress = Get-ProgressHash -Invocation $MyInvocation

$blockName = "[DEVELOPFRIENDLY][Windows Server]:Changing certificateValidationMode"
Write-Host $blockName
Write-Warning "$blockName - ONLY USE THIS FOR A LOCAL DEVELOPMENT INSTANCE!"


$blockName = "Getting deployment information: website name"
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

$websitename = Get-ISHDeploymentParameters | Where-Object -Property Name -EQ websitename | Select-Object -ExpandProperty Value
Write-Verbose "Website name: $websitename" 

$blockName = "Processing all web.config files, except InfoShareSTS"
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

Get-ISHDeploymentParameters | Where-Object -Property Name -Like "infoshare*webappname" | Where-Object -Property Name -NE "infosharestswebappname" | ForEach-Object {
    $ISSWebFullAppName = "IIS:\Sites\$($websitename)\$($_.Value)"
    $fullPath = "$($(Get-WebFilePath $ISSWebFullAppName).FullName)\web.config"

    $blockName = "Updating $fullPath - setting certificateValidationMode to: $certificateValidationMode"
    Write-Progress @scriptProgress -Status $blockName
    Write-Host $blockName
    [xml]$webConfigXML = Get-Content $fullPath
    Write-Verbose "certificateValidationMode - change from: $webConfigXML.configuration.'system.identityModel'.identityConfiguration.certificateValidation.certificateValidationMode to: $certificateValidationMode"
    $webConfigXML.configuration."system.identityModel".identityConfiguration.certificateValidation.certificateValidationMode = $certificateValidationMode
    $webConfigXML.Save($fullPath)
}

Write-Separator -Invocation $MyInvocation -Footer