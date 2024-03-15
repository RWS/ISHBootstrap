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

<#
.Synopsis
   Sets the centralized configuration on the database
.DESCRIPTION
   Using ISHRemote to:
   Upload the EnterViaUI xml files,
   Create/update output formats (depending on the configured integrations)
.EXAMPLE
   Update-ISHDBConfiguration
#>
function Update-ISHDBConfiguration {
    [OutputType([String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $ISHDeploymentSplat = @{}
        $newIshWsSessionSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
			$newIshWsSessionSplat = @{ISHDeployment = $ISHDeployment}
        }
        $deployment = Get-ISHDeployment @ISHDeploymentSplat
        if (($deployment.SoftwareVersion.Major -gt 15) -or (($deployment.SoftwareVersion.Major -eq 15) -and ($deployment.SoftwareVersion.Minor -ge 1))) {
            $newIshWsSessionSplat['Protocol'] = 'WcfSoapWithWsTrust'
        }

        # The EnterViaUI xml files,
        $enterViaUIPath = Get-ISHDeploymentPath -EnterViaUI @ISHDeploymentSplat
        Write-Debug "enterViaUIPath.AbsolutePath=$($enterViaUIPath.AbsolutePath)"

        <# To get a list with ISHRemote
        $typeDefinition=Get-IshTypeFieldDefinition -IshSession $session |Where-Object -Property ISHType -EQ ISHConfiguration
        $typeDefinition|Ft Name,Description -Wrap
        #>
        # Create a known mapping between filenames and field name in ISHConfiguration
        $fileNameFieldNameMap = @{
            "Admin.XMLBackgroundTaskConfiguration.xml"   = "FISHBACKGROUNDTASKCONFIG"
            "Admin.XMLChangeTrackerConfig.xml"           = "FISHCHANGETRACKERCONFIG"
            "Admin.XMLCollectiveSpacesConfiguration.xml" = "FISHCOLLECTIVESPACESCFG"
            "Admin.XMLExtensionConfiguration.xml"        = "FISHEXTENSIONCONFIG"
            "Admin.XMLInboxConfiguration.xml"            = "FISHINBOXCONFIGURATION"
            "Admin.XMLReportConfiguration.xml"           = "FISHREPORTCONFIGURATION"
            "Admin.XMLPublishPluginConfiguration.xml"    = "FISHPUBLISHPLUGINCONFIG"
            "Admin.XMLStatusConfiguration.xml"           = "FSTATECONFIGURATION"
            "Admin.XMLTranslationConfiguration.xml"      = "FTRANSLATIONCONFIGURATION"
            "Admin.XMLWriteObjPluginConfig.xml"          = "FISHWRITEOBJPLUGINCFG"
        }

        foreach ($fnfn in $fileNameFieldNameMap.GetEnumerator()) { Write-Debug "$($fnfn.Key)=$($fnfn.Value)" }

    }

    process {
        try {
            # Create new ishremote session
            Write-Debug "Creating ISHRemote remote session"

            $session = New-ISHWSSession -ServiceAdmin @newIshWsSessionSplat
            Write-Verbose "ISHRemote remote session created"
            $typeDefinition = (Get-IshTypeFieldDefinition -IshSession $session |Where-Object -Property ISHType -EQ ISHConfiguration).Name
            # Process each xml file inside enterviaui folder
            # TODO XMLAdminOrder Should there be a order in the files?
            Get-ChildItem -Path $enterViaUIPath.AbsolutePath -Filter "*.xml" | ForEach-Object {
                $fileName = $_.Name
                $filePath = $_.FullName

                Write-Debug "fileName=$fileName"
                Write-Debug "filePath=$filePath"

                $fieldName = $fileNameFieldNameMap[$fileName]
                # Check if the filename has a known field mapping
                if ($fileNameFieldNameMap.ContainsKey($fileName) -and $typeDefinition -contains $fieldName) {
                    Write-Debug "fieldName=$fieldName"
                    $xmlFromDatabase = Get-IshSetting -FieldName $fieldName -IshSession $session
                    $xmlFromFile = Get-Content -Path $filePath -Raw

                    Write-Debug "Comparing xml in database with local file system"
                    if ($xmlFromDatabase -ne $xmlFromFile) {
                        Write-Debug "XML in file is different than in database"
                        Write-Debug "Uploading $filePath into configuration with field name $fieldName"
                        $null = Set-IshSetting -IshSession $session -FieldName $fieldName -Value $xmlFromFile
                        Write-Verbose "Uploaded $filePath into configuration with field name $fieldName"
                    }
                    else {
                        Write-Verbose "Content of $filePath is identical to content of configuration field $fieldName"
                    }
                }
                else {
                    Write-Warning "Cannot map filename $fileName to field. Skipping"
                }
            }
        }
        finally {
            if ($session) {
                Write-Debug "Disposing session"
                try {
                    $session.Dispose()
                }
                catch {
                    Write-Debug $_.Exception
                }
            }
        }
    }

    end {

    }
}
