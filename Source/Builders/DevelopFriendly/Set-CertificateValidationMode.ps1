
param(
    [Parameter(Mandatory=$false)]
    [string]$certificateValidationMode = "None"

)


$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"

Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation


$blockName="[DEVELOPFRIENDLY][Windows Server]:Changing certificateValidationMode"
Write-Host $blockName
Write-Warning "$blockName - ONLY USE THIS FOR A LOCAL DEVELOPMENT INSTANCE!"


$blockName="Getting deployment information"
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

$deploymentParameters = Get-ISHDeploymentParameters # -ISHDeployment $ishDeploymentName

$paramWebPath = $deploymentParameters |Where-Object -Property Name -EQ "webpath"|Select-Object -ExpandProperty Value
$paramProjectSuffix = $deploymentParameters |Where-Object -Property Name -EQ "projectsuffix"|Select-Object -ExpandProperty Value


$webPath = "$paramWebPath\Web$paramProjectSuffix\Author\ASP"
$webConfig = "web.config"
$fullISHCMPath = "$webPath\$webConfig"
Write-Verbose "ISHCM web.config: $fullISHCMPath"

$webPath = "$paramWebPath\Web$paramProjectSuffix\InfoShareCE"
$webConfig = "web.config"
$fullISHCEPath = "$webPath\$webConfig"
Write-Verbose "ISHCE web.config: $fullISHCEPath"

$webPath = "$paramWebPath\Web$paramProjectSuffix\InfoShareWS"
$webConfig = "web.config"
$fullISHWSPath = "$webPath\$webConfig"
Write-Verbose "ISHSTS web.config: $fullISHWSPath"

$fullPaths = @($fullISHCMPath,$fullISHCEPath,$fullISHWSPath)


$blockName="Processing all web.config files"
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

foreach($fullPath in $fullPaths)
{
    $blockName="Updating $fullPath - setting certificateValidationMode to: $certificateValidationMode"
    Write-Progress @scriptProgress -Status $blockName
    Write-Host $blockName
    [xml]$webConfigXML = Get-Content $fullPath
    Write-Verbose "certificateValidationMode - change from: $webConfigXML.configuration.'system.identityModel'.identityConfiguration.certificateValidation.certificateValidationMode to: $certificateValidationMode"
    $webConfigXML.configuration."system.identityModel".identityConfiguration.certificateValidation.certificateValidationMode = $certificateValidationMode
    $webConfigXML.Save($fullPath)
}

Write-Separator -Invocation $MyInvocation -Footer