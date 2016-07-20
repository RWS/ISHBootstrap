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
        $Suffix="",
        [Parameter(Mandatory=$false)]
        $RootPath="C:\InfoShare\$Version",
        [Parameter(Mandatory=$false)]
        [int]$LucenePort="8080",
        [Parameter(Mandatory=$false)]
        [switch]$UseRelativePaths=$false,
        [Parameter(Mandatory=$false)]
        $ServiceCertificateThumbprint=$null
    )
    $computerName=$env:COMPUTERNAME.ToLower()
    $infosharestswebappname="ISHSTS$Suffix".ToLower()

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
    $inputParameters["projectsuffix"]=$Suffix
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
        $inputParameters["apppath"]=Join-Path $inputParameters["apppath"] "ISH$Suffix"
        $inputParameters["datapath"]=Join-Path $inputParameters["datapath"] "ISH$Suffix"
        $inputParameters["webpath"]=Join-Path $inputParameters["webpath"] "ISH$Suffix"
    }
    else
    {
        $inputParameters["apppath"]=Join-Path $inputParameters["apppath"] "ISH"
        $inputParameters["datapath"]=Join-Path $inputParameters["datapath"] "ISH"
        $inputParameters["webpath"]=Join-Path $inputParameters["webpath"] "ISH"
    }

    $inputParameters["infoshareauthorwebappname"]="ISHCM$Suffix".ToLower()
    $inputParameters["infosharewswebappname"]="ISHWS$Suffix".ToLower()
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