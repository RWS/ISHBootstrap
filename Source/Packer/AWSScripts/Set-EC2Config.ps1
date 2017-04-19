function Format-XML ([xml]$xml, $indent=2) 
{ 
    $StringWriter = New-Object System.IO.StringWriter 
    $XmlWriter = New-Object System.XMl.XmlTextWriter $StringWriter 
    $xmlWriter.Formatting = "indented" 
    $xmlWriter.Indentation = $Indent 
    $xml.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush() 
    $StringWriter.Flush() 
    Write-Output $StringWriter.ToString() 
}

$ec2ConfigPath = Join-Path (Get-Item Env:\ProgramFiles).Value "Amazon\Ec2ConfigService\Settings"

$ec2ConfigFile = Join-Path $ec2ConfigPath "Config.xml"
$ec2BundleConfigFile = Join-Path $ec2ConfigPath "BundleConfig.xml"

[xml]$config = Get-Content -Path $ec2ConfigFile
foreach ($t in $config.EC2ConfigurationSettings.Plugins.Plugin) {
    if ($t.Name -eq "Ec2SetPassword") {
        $t.State = "Enabled"
    }
    if ($t.Name -eq "Ec2SetComputerName") {
        $t.State = "Enabled"
    }
<#
    if ($t.Name -eq "Ec2HandleUserData") {
        $t.State = "Enabled"
    }
#>
}
Format-XML $config.InnerXml | Set-Content -Path $ec2ConfigFile

<#
[xml]$bundleConfig = Get-Content -Path $ec2BundleConfigFile
foreach ($t in $bundleConfig.BundleConfig.Property) {
    if ($t.Name -eq "AutoSysprep") {
        $t.Value = ""
    }
    if ($t.Name -eq "SetPasswordAfterSysprep") {
        $t.Value = ""
    }
}
Format-XML $bundleConfig.InnerXml | Set-Content -Path $ec2BundleConfigFile
#>