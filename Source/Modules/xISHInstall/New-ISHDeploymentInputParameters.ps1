function New-ISHDeploymentInputParameters {
    param (
        [Parameter(Mandatory=$true)]
        $CDPath,
        [Parameter(Mandatory=$true)]
        $Version,
        [Parameter(Mandatory=$true)]
        $OSUser,
        [Parameter(Mandatory=$true)]
        $OSPassword,
        [Parameter(Mandatory=$true)]
        $ConnectionString,
        [Parameter(Mandatory=$false)]
        [switch]$IsOracle=$false,
        [Parameter(Mandatory=$false)]
        [ValidatePattern("(?# Name doesn't start with InfoShare)InfoShare.*")]
        $Name="InfoShare",
        [Parameter(Mandatory=$false)]
        $RootPath="C:\InfoShare\$Version",
        [Parameter(Mandatory=$false)]
        [int]$LucenePort="8080",
        [Parameter(Mandatory=$false)]
        [switch]$UseRelativePaths=$false,
        [Parameter(Mandatory=$false)]
        $ServiceCertificateThumbprint=$null
    )
    $isMatch=$Name -match "InfoShare(?<suffix>.*)"
    $suffix=$Matches["suffix"]

    $computerName=$env:COMPUTERNAME.ToLower()
    $infosharestswebappname="ISHSTS$suffix".ToLower()

    if($ServiceCertificateThumbprint -eq $null)
    {
        $ServiceCertificateThumbprint=(Get-WebBinding 'Default Web Site' -Protocol "https").certificateHash
    }
    $serviceCertificate=Get-ChildItem -path "cert:\LocalMachine\My" | Where-Object {$_.Thumbprint -eq $ServiceCertificateThumbprint}
    #Take the fqdn from the web site's attached certificate or from the Service Certificate thumbprint
    $fqdn=(($serviceCertificate.Subject -split ', ')[0] -split '=')[1];
    $baseUrl="https://$fqdn".ToLower()

    $inputParameters=@{}
    $inputParameters["osuser"]=$OSUser
    $inputParameters["ospassword"]=$OSPassword
    $inputParameters["connectstring"]=$ConnectionString
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
    $inputParameters["localservicehostname"]="$computerName"
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
    $inputParameters["infosharewswebappname"]="ISHWS$suffix".ToLower()
    $inputParameters["infosharestswebappname"]=$infosharestswebappname
    $inputParameters["servicecertificatethumbprint"]=$ServiceCertificateThumbprint

    $inputParameters["issuerwstrustbindingtype"]="UsernameMixed"

    $ishSTSType=$inputParameters["issuerwstrustbindingtype"].Replace("Mixed","").ToLower()
    $inputParameters["issuerwsfederationendpointurl"]="$baseurl/$infosharestswebappname/issue/wsfed"
    $inputParameters["issuerwstrustmexurl"]="$baseurl/$infosharestswebappname/issue/wstrust/mex"
    $inputParameters["issuerwstrustendpointurl"]="$baseurl/$infosharestswebappname/issue/wstrust/mixed/$ishSTSType"
    $inputParameters["issuercertificatethumbprint"]=$inputParameters["servicecertificatethumbprint"]
    $inputParameters["issuercertificatevalidationmode"]="ChainTrust"

    $inputParametersPath=Join-Path $CDPath "__InstallTool\inputparameters.xml"
    [xml]$xml=Get-Content $inputParametersPath
    
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

    
    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
    $xmlWriter.Formatting = "indented" 
    $xmlWriter.Indentation = 2 
    $xml.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush() 
    $StringWriter.Flush() 
    Write-Output $StringWriter.ToString() 
}