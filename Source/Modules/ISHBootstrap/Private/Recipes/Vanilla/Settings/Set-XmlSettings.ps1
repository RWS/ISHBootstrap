Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

Write-Debug "Creating new ISHRemote IshSession"
$ishSession = New-ISHWSSession -ServiceAdmin

$settingsFolderPath = (Get-ISHDeploymentPath -EnterViaUI).AbsolutePath

Write-Verbose "Submitting Xml Settings from $settingsFolderPath"
$filePath = Join-Path -Path $settingsFolderPath -ChildPath "Admin.XMLInboxConfiguration.xml"
Set-IshSetting -IshSession $ishSession -FieldName "FINBOXCONFIGURATION" -FilePath $filePath
$filePath = Join-Path -Path $settingsFolderPath -ChildPath "Admin.XMLBackgroundTaskConfiguration.xml"
Set-IshSetting -IshSession $ishSession -FieldName "FISHBACKGROUNDTASKCONFIG" -FilePath $filePath
$filePath = Join-Path -Path $settingsFolderPath -ChildPath "Admin.XMLChangeTrackerConfig.xml"
Set-IshSetting -IshSession $ishSession -FieldName "FISHCHANGETRACKERCONFIG" -FilePath $filePath
$filePath = Join-Path -Path $settingsFolderPath -ChildPath "Admin.XMLExtensionConfiguration.xml"
Set-IshSetting -IshSession $ishSession -FieldName "FISHEXTENSIONCONFIG" -FilePath $filePath
$filePath = Join-Path -Path $settingsFolderPath -ChildPath "Admin.XMLPluginConfig.xml"
Set-IshSetting -IshSession $ishSession -FieldName "FISHPLUGINCONFIGXML" -FilePath $filePath
$filePath = Join-Path -Path $settingsFolderPath -ChildPath "Admin.XMLStatusConfiguration.xml"
Set-IshSetting -IshSession $ishSession -FieldName "FSTATECONFIGURATION" -FilePath $filePath
$filePath = Join-Path -Path $settingsFolderPath -ChildPath "Admin.XMLTranslationConfiguration.xml"
Set-IshSetting -IshSession $ishSession -FieldName "FTRANSLATIONCONFIGURATION" -FilePath $filePath
$filePath = Join-Path -Path $settingsFolderPath -ChildPath "Admin.XMLWriteObjPluginConfig.xml"
Set-IshSetting -IshSession $ishSession -FieldName "FISHWRITEOBJPLUGINCFG" -FilePath $filePath
$filePath = Join-Path -Path $settingsFolderPath -ChildPath "Admin.XMLPublishPluginConfiguration.xml"
Set-IshSetting -IshSession $ishSession -FieldName "FISHPUBLISHPLUGINCONFIG" -FilePath $filePath
$filePath = Join-Path -Path $settingsFolderPath -ChildPath "Admin.XMLCollectiveSpacesConfiguration.xml"
Set-IshSetting -IshSession $ishSession -FieldName "FISHCOLLECTIVESPACESCFG" -FilePath $filePath
Write-Host "Done"

