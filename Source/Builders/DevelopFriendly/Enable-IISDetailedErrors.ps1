param(

)


$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"

Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation


$CustomErrorsMode = "Off"
$HttpErrorserrorMode = "Detailed"
$AspScriptErrorSentToBrowser = "true"


[xml]$CustomErrorsXml = @"
<customErrors mode="$CustomErrorsMode"><!-- ISHTROUBLESHOOTING --></customErrors>
"@

[xml]$HttpErrorsXml = @"
 <httpErrors errorMode="$HttpErrorserrorMode"><!-- ISHTROUBLESHOOTING --></httpErrors>
"@

[xml]$AspScriptErrorSentToBrowserXml = @"
<asp scriptErrorSentToBrowser="true"><!-- ISHTROUBLESHOOTING --></asp>
"@

$blockName="[DEVELOPFRIENDLY][Windows Server]:Enabling IIS Detailed Errors"
Write-Host $blockName
Write-Warning "$blockName - ONLY USE THIS FOR TROUBLESHOOTING A LOCAL DEVELOPMENT INSTANCE!"


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

$webPath = "$paramWebPath\Web$paramProjectSuffix\InfoShareSTS"
$webConfig = "web.config"
$fullISHSTSPath = "$webPath\$webConfig"
Write-Verbose "ISHSTS web.config: $fullISHSTSPath"

$fullPaths = @($fullISHCMPath,$fullISHCEPath,$fullISHSTSPath)


$blockName="Processing all web.config files"
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

foreach($fullPath in $fullPaths)
{
    $blockName="Updating $fullPath"
    Write-Progress @scriptProgress -Status $blockName
    Write-Host $blockName
    #customErrors - mode attribute
    [xml]$webConfigXML = Get-Content $fullPath
    if ($webConfigXML.configuration."system.web".customErrors -and $webConfigXML.configuration."system.web".customErrors.mode)
    {
        Write-Verbose "customErrors - change: 'mode' attribute from: $webConfigXML.configuration.'system.web'.customErrors.mode to: $CustomErrorsMode"
        $webConfigXML.configuration."system.web".customErrors.mode = $CustomErrorsMode
    }
    elseif ($webConfigXML.configuration."system.web".customErrors -and -not($wnebConfigXML.configuration."system.web".customErrors.mode))
    {
        Write-Verbose "customErrors - add: 'mode' attribute with value: $CustomErrorsMode"
        $webConfigXML.configuration."system.web".customErrors.SetAttribute("mode", $CustomErrorsMode)
    }
    elseif (-not $webConfigXML.configuration."system.web".customErrors)
    {
        Write-Verbose "customErrors - add: 'customErrors' element and 'mode' attribute with value: $CustomErrorsMode"
        $webConfigXML.configuration."system.web".AppendChild($webConfigXML.ImportNode($CustomErrorsXml.customErrors, $true))
    }

    #httpErrors - errorMode attribute
    if ($webConfigXML.configuration."system.webserver".httpErrors -and $webConfigXML.configuration."system.webserver".httpErrors.errorMode)
    {
        Write-Verbose "httpErrors - change: 'errorMode' attribute from: $webConfigXML.configuration.'system.webserver'.httpErrors.errorMode to: $HttpErrorserrorMode"
        $webConfigXML.configuration."system.webserver".httpErrors.errorMode = $HttpErrorserrorMode
    }
    elseif ($webConfigXML.configuration."system.webserver".httpErrors -and -not($webConfigXML.configuration."system.webserver".httpErrors.errorMode))
    {
        Write-Verbose "httpErrors - add: 'errorMode' attribute with value: $HttpErrorserrorMode"
        $webConfigXML.configuration."system.webserver".httpErrors.SetAttribute("errorMode", $HttpErrorserrorMode)
    }
    elseif (-not $webConfigXML.configuration."system.webserver".httpErrors)
    {
        Write-Verbose "customErrors - add: 'httpErrors' element and 'errorMode' attribute with value: $HttpErrorserrorMode"
        $webConfigXML.configuration."system.webserver".AppendChild($webConfigXML.ImportNode($HttpErrorsXml.httpErrors, $true))
    }

    #asp - scriptErrorSentToBrowser attribute
    if ($webConfigXML.configuration."system.webserver".asp -and $webConfigXML.configuration."system.webserver".asp.scriptErrorSentToBrowser)
    {
        Write-Verbose "asp - change: 'scriptErrorSentToBrowser' $webConfigXML.configuration.'system.webserver'.asp.scriptErrorSentToBrowser to: $AspScriptErrorSentToBrowser"
        $webConfigXML.configuration."system.webserver".asp.scriptErrorSentToBrowser = "$ScriptErrorSentToBrowser"
    }
    elseif ($webConfigXML.configuration."system.webserver".asp -and -not($webConfigXML.configuration."system.webserver".asp.scriptErrorSentToBrowser))
    {
        Write-Verbose "asp - add: 'scriptErrorSentToBrowser attribute with value: $AspScriptErrorSentToBrowser"
        $webConfigXML.configuration."system.webserver".asp.SetAttribute("scriptErrorSentToBrowser", $AspScriptErrorSentToBrowser)
    }
    elseif (-not $webConfigXML.configuration."system.webserver".asp)
    {
        Write-Verbose "asp - add: 'asp' element and 'scriptErrorSentToBrowser' attribute with value: $AspScriptErrorSentToBrowser"
        $webConfigXML.configuration."system.webserver".AppendChild($webConfigXML.ImportNode($AspScriptErrorSentToBrowserXml.asp, $true))
    }

    $webConfigXML.Save($fullPath)
}

Write-Separator -Invocation $MyInvocation -Footer