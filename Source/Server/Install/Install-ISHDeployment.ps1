<#
# Copyright (c) 2022 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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
    [string]$Computer=$null,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [string]$ISHVersion,
    [Parameter(Mandatory=$true)]
    [pscredential]$OSUserCredential,
    [Parameter(Mandatory=$true)]
    $ConnectionString,
    [Parameter(Mandatory=$false)]
    [switch]$IsOracle=$false,
    [Parameter(Mandatory=$false)]
    [ValidatePattern("(?# Name doesn't start with InfoShare)InfoShare.*")]
    $Name="InfoShare",
    [Parameter(Mandatory=$false)]
    $RootPath="C:\InfoShare\$ISHVersion",
    [Parameter(Mandatory=$false)]
    [int]$LucenePort="8080",
    [Parameter(Mandatory=$false)]
    [switch]$UseRelativePaths=$false,
    [Parameter(Mandatory=$false)]
    [string]$HostName=$null,
    [Parameter(Mandatory=$false)]
    [string]$LocalServiceHostName=$null,
    [Parameter(Mandatory=$false)]
    [string]$MachineName=$null,
    [Parameter(Mandatory=$false)]
    $AMConnectionString,
    [Parameter(Mandatory=$false)]
    $BFFConnectionString,
    [Parameter(Mandatory=$false)]
    $IDConnectionString
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$findCDPath={
    $major=($ISHVersion -split '\.')[0]
    $revision=($ISHVersion -split '\.')[2]
    $expandedCDs=Get-ISHCD -ListAvailable|Where-Object -Property IsExpanded -EQ $true
    $matchingVersionCDs=$expandedCDs|Where-Object -Property Major -EQ $major |Where-Object -Property Revision -EQ $revision
    $availableCD=$matchingVersionCDs|Sort-Object -Descending -Property Build
    if(-not $availableCD)
    {
        throw "No matching CD found"
        return
    }
    if($availableCD -is [array])
    {
        $availableCD=$availableCD[0]
        Write-Warning "Found more than one cd. Using $($availableCD.Name)"
    }
    $availableCD.ExpandedPath
}


$newParameterScriptBlock={

    $isMatch=$Name -match "InfoShare(?<suffix>.*)"
    $suffix=$Matches["suffix"]
    $major=($ISHVersion -split '\.')[0]

    $revision=($ISHVersion -split '\.')[2]
    
    $computerName=$env:COMPUTERNAME.ToLower()
    $infosharestswebappname="ISHSTS$suffix".ToLower()

    $serviceCertificateThumbprint=(Get-WebBinding 'Default Web Site' -Protocol "https").certificateHash

    $serviceCertificate=Get-ChildItem -path "cert:\LocalMachine\My" | Where-Object {$_.Thumbprint -eq $serviceCertificateThumbprint}
    if($HostName)
    {
        $baseUrl="https://$HostName"
    }
    else
    {
        #Take the fqdn from the web site's attached certificate or from the Service Certificate thumbprint
        $fqdn=(($serviceCertificate.Subject -split ', ')[0] -split '=')[1];
        $baseUrl="https://$fqdn".ToLower()
    }

    $osUserNetworkCredential=$OSUserCredential.GetNetworkCredential()
    if($osUserNetworkCredential.Domain -and ($osUserNetworkCredential.Domain -ne ""))
    {
        $osUser=$osUserNetworkCredential.Domain
    }
    else
    {
        $osUser="."
    }
    $osUser+="\"+$osUserNetworkCredential.UserName
    $osPassword=$osUserNetworkCredential.Password



    $inputParameters=@{}
    $inputParameters["osuser"]=$osUser
    $inputParameters["ospassword"]=$osPassword
    $inputParameters["connectstring"]=$ConnectionString
    if($major -ge 15){
        $inputParameters["ishamconnectstring"]=$AMConnectionString
        $inputParameters["ishbffconnectstring"]=$BFFConnectionString
        $inputParameters["ishidconnectstring"]=$IDConnectionString
        $inputParameters["serviceaccountclientsecret"]="MockServiceAccountClientSecret"
        $inputParameters["serviceaccountclientid"]="MockServiceAccountClientId"
    }
    
    if($IsOracle)
    {
        $inputParameters["databasetype"]="oracle"    
    }
    else
    {
        $inputParameters["databasetype"]="sqlserver"
    }
    $inputParameters["projectsuffix"]=$suffix
    $inputParameters["baseurl"]=$baseUrl
    if($LocalServiceHostName)
    {
        $inputParameters["localservicehostname"]="$LocalServiceHostName"
    }
    else
    {
        $inputParameters["localservicehostname"]="$computerName"
    }
    $inputParameters["apppath"]=$RootPath
    $inputParameters["datapath"]=$RootPath
    $inputParameters["webpath"]=$RootPath
    $inputParameters["workspacepath"]=Join-Path $RootPath "_Workspace"
    $inputParameters["solrlucene_service_port"]=$LucenePort
    $inputParameters["solrlucene_stop_port"]=$LucenePort+1
    
    if($UseRelativePaths)
    {
        $inputParameters["apppath"]=Join-Path $inputParameters["apppath"] "ISH$suffix"
        $inputParameters["datapath"]=Join-Path $inputParameters["datapath"] "ISH$suffix"
        $inputParameters["webpath"]=Join-Path $inputParameters["webpath"] "ISH$suffix"
    }
    else
    {
        $inputParameters["apppath"]=Join-Path $inputParameters["apppath"] "ISH"
        $inputParameters["datapath"]=Join-Path $inputParameters["datapath"] "ISH"
        $inputParameters["webpath"]=Join-Path $inputParameters["webpath"] "ISH"
    }

    $inputParameters["infoshareauthorwebappname"]="ISHCM$suffix".ToLower()
    if($major -ge 14)
    {
        $inputParameters["infosharecswebappname"]="ISHCS$suffix".ToLower()
    }
    $inputParameters["infosharewswebappname"]="ISHWS$suffix".ToLower()
    $inputParameters["infosharestswebappname"]=$infosharestswebappname
    $inputParameters["servicecertificatethumbprint"]=$serviceCertificateThumbprint

    $inputParameters["issuerwstrustbindingtype"]="UsernameMixed"

    $ishSTSType=$inputParameters["issuerwstrustbindingtype"].Replace("Mixed","").ToLower()
    $inputParameters["issuerwsfederationendpointurl"]="$baseurl/$infosharestswebappname/issue/wsfed"
    $inputParameters["issuerwstrustmexurl"]="$baseurl/$infosharestswebappname/issue/wstrust/mex"
    $inputParameters["issuerwstrustendpointurl"]="$baseurl/$infosharestswebappname/issue/wstrust/mixed/$ishSTSType"
    $inputParameters["issuercertificatethumbprint"]=$inputParameters["servicecertificatethumbprint"]

    if($MachineName)
    {
        $inputParameters["machinename"]=$MachineName
    }

    if ($major -eq 14) {
        $javaLocation = "C:\AdoptOpenJDK"
    } elseif ($major -eq 15) {
        $javaLocation = "C:\EclipseAdoptiumOpenJDK"
    }

    $value=Get-ChildItem -Path $javaLocation |Sort-Object -Property Name -Descending|Select-Object -First 1 -ExpandProperty FullName
    $inputParameters["ps_java_home"]="$value"
    $inputParameters["ps_java_jvmdll"]="$value\bin\server\jvm.dll"

    $inputParametersPath=Join-Path $CDPath "__InstallTool\inputparameters.xml"
    [xml]$xml=Get-Content $inputParametersPath

    #region Add the missing xml elements

    if($suffix -ne "")
    {
        $node=$xml | Select-Xml -XPath "//param[@name='projectsuffix']"
        if(-not $node)
        {
            $param = $xml.CreateElement('param')
            $param.SetAttribute('name','projectsuffix') |Out-Null
            
            $currentValue = $xml.CreateElement('currentvalue')
            $currentValue.InnerText=$suffix
            $param.AppendChild($currentValue) |Out-Null

            $defaultvalue = $xml.CreateElement('defaultvalue')
            $param.AppendChild($defaultvalue) |Out-Null

            $description = $xml.CreateElement('description')
            $param.AppendChild($description) |Out-Null

            $validate = $xml.CreateElement('validate')
            $param.AppendChild($validate) |Out-Null

            $xml.inputconfig.AppendChild($param) |Out-Null
        }
    }

    if($HostName)
    {
        $node=$xml | Select-Xml -XPath "//param[@name='baseurl']"
        if(-not $node)
        {
            $param = $xml.CreateElement('param')
            $param.SetAttribute('name','baseurl') |Out-Null
            
            $currentValue = $xml.CreateElement('currentvalue')
            $currentValue.InnerText=$inputParameters["baseurl"]
            $param.AppendChild($currentValue) |Out-Null

            $defaultvalue = $xml.CreateElement('defaultvalue')
            $param.AppendChild($defaultvalue) |Out-Null

            $description = $xml.CreateElement('description')
            $param.AppendChild($description) |Out-Null

            $validate = $xml.CreateElement('validate')
            $param.AppendChild($validate) |Out-Null

            $xml.inputconfig.AppendChild($param) |Out-Null
        }
    }
    if($LocalServiceHostName)
    {
        $node=$xml | Select-Xml -XPath "//param[@name='localservicehostname']"
        if(-not $node)
        {
            $param = $xml.CreateElement('param')
            $param.SetAttribute('name','localservicehostname') |Out-Null
            
            $currentValue = $xml.CreateElement('currentvalue')
            $currentValue.InnerText=$inputParameters["localservicehostname"]
            $param.AppendChild($currentValue) |Out-Null

            $defaultvalue = $xml.CreateElement('defaultvalue')
            $param.AppendChild($defaultvalue) |Out-Null

            $description = $xml.CreateElement('description')
            $param.AppendChild($description) |Out-Null

            $validate = $xml.CreateElement('validate')
            $param.AppendChild($validate) |Out-Null

            $xml.inputconfig.AppendChild($param) |Out-Null
        }
    }
    if($MachineName)
    {
        $node=$xml | Select-Xml -XPath "//param[@name='machinename']"
        if(-not $node)
        {
            $param = $xml.CreateElement('param')
            $param.SetAttribute('name','machinename') |Out-Null
            
            $currentValue = $xml.CreateElement('currentvalue')
            $currentValue.InnerText=$inputParameters["machinename"]
            $param.AppendChild($currentValue) |Out-Null

            $defaultvalue = $xml.CreateElement('defaultvalue')
            $param.AppendChild($defaultvalue) |Out-Null

            $description = $xml.CreateElement('description')
            $param.AppendChild($description) |Out-Null

            $validate = $xml.CreateElement('validate')
            $param.AppendChild($validate) |Out-Null

            $xml.inputconfig.AppendChild($param) |Out-Null
        }
    }

    #endregion

    foreach($key in $inputParameters.Keys)
    {
        $node=$xml | Select-Xml -XPath "//param[@name='$key']/currentvalue"
        if($node)
        {
            $node.Node.InnerText=$inputParameters[$key]
        }
    }

    
    #Desible validations
    
    $node=$xml | Select-Xml -XPath "//param[@name='ps_fo_processor']/validate"
    if($node)
    {
        $node.Node.InnerText=""
    }

    $fileName="inputparameters-$Name.xml"
    $folderPath=Resolve-Path "$CDPath\.."
    Write-Debug "folderPath=$folderPath"
    $filePath=Join-Path $folderPath $fileName
    Write-Debug "filePath=$filePath"

    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
    $xmlWriter.Formatting = "indented" 
    $xmlWriter.Indentation = 2 
    $xml.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush() 
    $StringWriter.Flush() 
    $StringWriter.ToString() |Out-File $filePath -Force
    Write-Verbose "Saved to $filePath"

<#
    While(-not (Test-Path $filePath))
    {
        Write-Warning "Test path $filePath failed. Sleeping"
        Start-Sleep -Milliseconds 500
    }
#>
    
}

$logLevelScriptBlock={
    $major=($ISHVersion -split '\.')[0]
    if($major -ge 14)
    {
        $requiredLevel="Info"
    }
    else
    {
        $requiredLevel="Debug"
    }
    $installToolNlogPath=Join-Path $CDPath "__InstallTool\NLog.config"
    Write-Debug "installToolNlogPath=$installToolNlogPath"

    [xml]$xml=Get-Content -Path $installToolNlogPath -Raw

    $nsmgr = New-Object System.Xml.XmlNamespaceManager $xml.NameTable
    $nsmgr.AddNamespace('ns','http://www.nlog-project.org/schemas/NLog.xsd')

    # Check if the debug level for the File target is set to Debug
    $xpathFileLoggerRule='ns:nlog/ns:rules/ns:logger[@writeTo="File"]'
    $nodeFileLoggerRule=$xml.SelectSingleNode($xpathFileLoggerRule, $nsmgr)

    if ($nodeFileLoggerRule.minLevel -ne $requiredLevel)
    {
        Write-Warning "Changing the minLevel attribute of the File logger from '$($nodeFileLoggerRule.minLevel)' to '$($requiredLevel)'"
        $nodeFileLoggerRule.minLevel="Debug"
        $xml.Save($installToolNlogPath)
        Write-Verbose "Saved to $installToolNlogPath"
    }
    else
    {
        Write-Warning "The minLevel attribute of the File logger is already set to '$($requiredLevel)'"
    }
}

$installScriptBlock={
    [int]$major=($ISHVersion -split '\.')[0]
    if($major -eq 13)
    {
        # Fixing JAVA_HOME not set because we didn't restart
        $envVarName="JAVA_HOME"
        if(-not (Get-Item -Path ENV:\$envVarName -ErrorAction SilentlyContinue))
        {
            $value=Get-ChildItem -Path $Env:ProgramFiles\Java |Sort-Object -Property Name -Descending|Select-Object -First 1 -ExpandProperty Name
            Set-Item -Path ENV:\$envVarName -Value $value
            Write-Warning "Environment variable $envVarName could not be retrieved. Setting to $value"
        }
    }

    $fileName="inputparameters-$Name.xml"
    $folderPath=Resolve-Path "$CDPath\.."
    $inputParametersPathPath=Join-Path $folderPath $fileName
    Write-Debug "inputParametersPathPath=$inputParametersPathPath"


    $installToolPath=Join-Path $CDPath "__InstallTool\InstallTool.exe"
    $installPlanPath=Join-Path $CDPath "__InstallTool\installplan.xml"
    $installToolArgs=@("-Install",
        "-cdroot",$CDPath,
        "-installplan",$installPlanPath
        "-inputparameters",$inputParametersPathPath
        )
    & $installToolPath $installToolArgs
}

try
{
    $blockName="Finding CD for $ISHVersion"
    Write-Progress @scriptProgress -Status $blockName
    $cdPath=Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $findCDPath -BlockName $blockName -UseParameters @("ISHVersion")

    $blockName="Creating new deployment parameters for $Name"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $newParameterScriptBlock -BlockName $blockName -UseParameters @("cdPath","ISHVersion","OSUserCredential","ConnectionString","IsOracle","Name","RootPath","LucenePort","UseRelativePaths")
    $blockName="Making sure that the minLevel of the File logger is set to 'Debug' for InstallTool"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $logLevelScriptBlock -BlockName $blockName -UseParameters @("cdPath","ISHVersion")
    
    $blockName="Installing $Name"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $installScriptBlock -BlockName $blockName -UseParameters @("cdPath","ISHVersion","Name")
}
catch
{
    Write-Error $_
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
