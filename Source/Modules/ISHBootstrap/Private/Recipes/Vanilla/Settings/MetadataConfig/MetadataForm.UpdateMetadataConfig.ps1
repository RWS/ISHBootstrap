
$webPath = $args[0]

set-strictmode -version 2.0

Import-Module ("$PSScriptRoot\MetadataConfig.psm1") -DisableNameChecking -Force

$metadataConfigPath = Get-DefaultMetadataConfigurationPath $webPath

function Set-CreateLogicalObjectForm
{
    Write-Verbose "Set form 'Test.CreateLogicalObjectForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
  <ishfrm id="Test.CreateLogicalObjectForm">
    <ishfrmgroup>
      <label resourceref="GeneralGroup.Label">General</label>
      <ishfrmfield id="TitleFieldMock" name="TitleField" ishfieldref="FTITLE" level="logical">
        <label resourceref="FTITLE.Label">&amp;Title</label>
        <description resourceref="FTITLE.Description">Title of the object.</description>
        <mandatory />
        <value overwrite="yes" ishcondition="CreateReason = 'NewObject'" />
        <value overwrite="yes" ishcondition="CreateReason = 'Duplicate'">
          <var name="logicalobjecttitle" />
        </value>
        <value overwrite="yes" ishcondition="CreateReason = 'Import' and ISHType in ('ISHIllustration', 'ISHTemplate')">
          <var name="filenamewithoutextension" />
        </value>
        <!--value overwrite="yes" ishcondition="CreateReason = 'Import' and ISHType in ('ISHModule', 'ISHMasterDoc', 'ISHLibrary')">
              <var name="documenttitle" />
            </value-->
      </ishfrmfield>
      <ishfrmfield id="IllustrationTypeFieldMock" name="IllustrationTypeField" ishfieldref="FILLUSTRATIONTYPE" level="logical" ishcondition="ISHType in ('ISHIllustration')">
        <label resourceref="FILLUSTRATIONTYPE.Label">I&amp;mage type</label>
        <description resourceref="FILLUSTRATIONTYPE.Description">Indicates the content type of the image.</description>
        <typepulldown>
          <valuelist>
            <lovlist ishlovref="DILLUSTRATIONTYPE" activityfilter="active" />
          </valuelist>
        </typepulldown>
      </ishfrmfield>
      <ishfrmfield id="LibraryTypeFieldMock" name="LibraryTypeField" ishfieldref="FLIBRARYTYPE" level="logical" ishcondition="ISHType in ('ISHLibrary')">
        <label resourceref="FLIBRARYTYPE.Label">&amp;Library topic type</label>
          <description resourceref="FLIBRARYTYPE.Description">Indicates the content type of the library topic.</description>
          <typepulldown>
          <valuelist>
            <lovlist ishlovref="DLIBRARYTYPE" activityfilter="active" />
          </valuelist>
          </typepulldown>
      </ishfrmfield>
      <ishfrmfield id="MasterTypeFieldMock" name="MasterTypeFieldMock" ishfieldref="FMASTERTYPE" level="logical" ishcondition="ISHType in ('ISHMasterDoc')">
        <label resourceref="FMASTERTYPE.Label">&amp;Map type</label>
        <description resourceref="FMASTERTYPE.Description">Indicates the content type of the map.</description>
        <typepulldown>
        <valuelist>
          <lovlist ishlovref="DMASTERTYPE" activityfilter="active" />
        </valuelist>
        </typepulldown>
      </ishfrmfield>
      <ishfrmfield id="ModuleTypeFieldMock" name="ModuleTypeFieldMock" ishfieldref="FMODULETYPE" level="logical" ishcondition="ISHType in ('ISHModule')">
        <label resourceref="FMODULETYPE.Label">T&amp;opic type</label>
        <description resourceref="FMODULETYPE.Description">Indicates the content type of the topic.</description>
        <typepulldown>
          <valuelist>
            <lovlist ishlovref="DMODULETYPE" activityfilter="active" />
          </valuelist>
        </typepulldown>
      </ishfrmfield>
      <ishfrmfield ref="DescriptionFieldMock" />
    </ishfrmgroup>
    <ishfrmgroup id="TranslationManagementGroupMock">
      <label resourceref="TranslationManagementGroup.Label">Translation management</label>
      <ishfrmfield name="TranslationManagementEnabledField" ishfieldref="FNOTRANSLATIONMGMT" level="logical">
        <label resourceref="FNOTRANSLATIONMGMT.Label">&amp;Enable translation management</label>
        <description resourceref="FNOTRANSLATIONMGMT.Description" />
        <typecheckbox>
          <checkedvalue>No</checkedvalue>
          <uncheckedvalue>Yes</uncheckedvalue>
        </typecheckbox>
        <value overwrite="yes" ishcondition="ChangeMode = 'Create' and ISHType in ('ISHMasterDoc', 'ISHLibrary', 'ISHModule')">No</value>
        <value overwrite="yes" ishcondition="ChangeMode = 'Create' and ISHType in ('ISHIllustration', 'ISHTemplate')">Yes</value>
        <value ishcondition="ChangeMode in ('Update','NewVersion') and ISHType in ('ISHMasterDoc', 'ISHLibrary', 'ISHModule')">No</value>
        <value ishcondition="ChangeMode in ('Update','NewVersion') and ISHType in ('ISHIllustration', 'ISHTemplate')">Yes</value>
      </ishfrmfield>
    </ishfrmgroup>
  </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.CreateLogicalObjectForm']"
    AppendChild $document "//*/ishfrm[@id='Test.CreateLogicalObjectForm']" "//*/ishfrms" $form

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-UpdateLogicalObjectForm
{
    Write-Verbose "Set form 'Test.UpdateLogicalObjectForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.UpdateLogicalObjectForm">
        <ishfrmgroup>
          <label resourceref="GeneralGroup.Label">General</label>
          <ishfrmfield ref="TitleFieldMock" />
          <ishfrmfield id="IdFieldMock" name="IdFieldMock" ishfieldref="ishref" level="object">
            <label resourceref="IdField.Label">Identifier</label>
            <description resourceref="IdField.Description">Unique identification of the object used for linking.</description>
            <typelabel />
            <hidden ishcondition="ChangeMode = 'Create' and CreateReason = 'NewObject'" />
            <mandatory />
          </ishfrmfield>
          <ishfrmfield ref="IllustrationTypeFieldMock" />
          <ishfrmfield ref="LibraryTypeFieldMock" />
          <ishfrmfield ref="MasterTypeFieldMock" />
          <ishfrmfield ref="ModuleTypeFieldMock" />
          <ishfrmfield id="DescriptionFieldMock" name="DescriptionFieldMock" ishfieldref="FDESCRIPTION" level="logical">
            <label resourceref="FDESCRIPTION.Label">&amp;Description</label>
            <description resourceref="FDESCRIPTION.Description">Free text that describes the object.</description>
            <typemultilinetext />
            <value overwrite="yes" ishcondition="ChangeMode = 'Create'" />
          </ishfrmfield>
        </ishfrmgroup>
        <ishfrmgroup ref="TranslationManagementGroupMock" />
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.UpdateLogicalObjectForm']"
    AppendChild $document "//*/ishfrm[@id='Test.UpdateLogicalObjectForm']" "//*/ishfrms" $form 

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-CreateVersionObjectForm
{
    Write-Verbose "Set form 'Test.CreateVersionObjectForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.CreateVersionObjectForm">
        <ishfrmgroup id="VersionGroupMock">
          <label resourceref="VersionGroup.Label">Version</label>
          <ishfrmfield ref="VersionField" />
          <ishfrmfield ref="ChangesField" />
          <ishfrmfield name="ReleaseCandidateField" ishfieldref="FISHRELEASECANDIDATE" level="version">
            <label resourceref="FISHRELEASECANDIDATE.Label">C&amp;andidate for baseline</label>
            <description resourceref="FISHRELEASECANDIDATE.Description">Candidate for baseline.</description>
            <typetaglist>
              <autosuggest>
                <valuelist ref="ActiveBaselineList" />
              </autosuggest>
              <structureview>
                <valuelist ref="ActiveBaselineList" />
              </structureview>
              <valuepanel>
                <valuelist ref="ActiveBaselineList" />
              </valuepanel>
            </typetaglist>
            <multivalue />
            <value overwrite="yes" ishcondition="ChangeMode in ('NewVersion', 'Create')" />
          </ishfrmfield>
          <ishfrmfield name="ReleaseLabelField" ishfieldref="FISHRELEASELABEL" level="version" ishcondition="ISHType in ('ISHMasterDoc', 'ISHIllustration', 'ISHLibrary', 'ISHModule')">
            <label resourceref="FISHRELEASELABEL.Label">&amp;Baseline label</label>
            <description resourceref="FISHRELEASELABEL.Description">Used for textual (alpha-numeric) labeling.</description>
            <typelabel />
            <value overwrite="yes" ishcondition="ChangeMode in ('NewVersion', 'Create')" />
          </ishfrmfield>
        </ishfrmgroup>
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.CreateVersionObjectForm']"
    AppendChild $document "//*/ishfrm[@id='Test.CreateVersionObjectForm']" "//*/ishfrms" $form

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-UpdateVersionObjectForm
{
    Write-Verbose "Set form 'Test.UpdateVersionObjectForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.UpdateVersionObjectForm">
        <ishfrmgroup ref="VersionGroupMock" />
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.UpdateVersionObjectForm']"
    AppendChild $document "//*/ishfrm[@id='Test.UpdateVersionObjectForm']" "//*/ishfrms" $form

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-CreateLanguageObjectForm
{
    Write-Verbose "Set form 'Test.CreateLanguageObjectForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
  <ishfrm id="Test.CreateLanguageObjectForm">
    <ishfrmgroup>
      <label resourceref="WorkflowGroup.Label">Workflow</label>
      <ishfrmfield name="DocumentLanguageField" ishfieldref="DOC-LANGUAGE" level="lng" ishcondition="ISHType in ('ISHMasterDoc', 'ISHLibrary', 'ISHModule')">
        <label resourceref="DOC-LANGUAGE.Label">&amp;Language</label>
        <description resourceref="DOC-LANGUAGE.Description">Document language.</description>
        <typepulldown>
          <valuelist ref="ActiveLanguageList" />
        </typepulldown>
        <mandatory />
        <value><var name="currentlanguage" /></value>
      </ishfrmfield>
      <ishfrmfield id="ImageLanguageField" name="DocumentLanguageField" ishfieldref="DOC-LANGUAGE" level="lng" ishcondition="ISHType='ISHIllustration'">
        <label resourceref="DOC-LANGUAGE.Label">&amp;Language</label>
        <description resourceref="DOC-LANGUAGE.Description">Document language.</description>
        <typetaglist>
        <autosuggest>
          <valuelist ref="ActiveLanguageList" />
        </autosuggest>
        <structureview>
          <valuelist ref="ActiveLanguageList" />
        </structureview>
        <valuepanel>
          <valuelist ref="ActiveLanguageList" />
        </valuepanel>
        </typetaglist>
        <mandatory />
        <multivalue />
        <value>
        <var name="currentlanguage" />
        </value>
      </ishfrmfield>
      <ishfrmfield name="StatusField" ishfieldref="FSTATUS" level="lng">
          <label resourceref="FSTATUS.Label">&amp;Status</label>
          <description resourceref="FSTATUS.Description">Indicator of the progress of the object.</description>
          <typepulldown>
            <valuelist>
              <transitionstatelist />
            </valuelist>
          </typepulldown>
          <mandatory />
          <!--value overwrite="yes" ishcondition="ChangeMode in ('NewVersion', 'Create')"/-->
          <value overwrite="yes" ishcondition="ChangeMode in ('Create', 'NewVersion')">
            <var name="initialstatus" />
          </value>
          <value ishcondition="ChangeMode='Update'">
            <var name="currentstatus" />
          </value>
      </ishfrmfield>
      <ishfrmfield name="AuthorField" ishfieldref="FAUTHOR" level="lng">
          <label resourceref="FAUTHOR.Label">&amp;Author</label>
          <description resourceref="FAUTHOR.Description">Name of the author.</description>
          <typepulldown>
            <valuelist ref="ActiveAuthorList" />
          </typepulldown>
          <mandatory />
          <!-- On a new language card the username of the template must be replaced by the name of the currentuser-->
          <value overwrite="yes" ishcondition="ChangeMode in ('NewVersion', 'Create')">
            <var name="currentusername" />
          </value>
          <!-- When updating the language card, only add the name of the currentuser when no value is given -->
          <value ishcondition="ChangeMode='Update'">
            <var name="currentusername" />
          </value>
      </ishfrmfield>
      <ishfrmfield ref="ReviewerFieldMock" />
      <ishfrmfield ref="TranslatorFieldMock" />
      <ishfrmfield ref="LastModifiedByFieldMock" />
      <ishfrmfield name="ResolutionField" ishfieldref="FRESOLUTION" level="lng" ishcondition="ISHType='ISHIllustration'">
        <label resourceref="FRESOLUTION.Label">Resolution</label>
        <description resourceref="FRESOLUTION.Description">Resolution of the image.</description>
        <typepulldown>
          <valuelist>
            <lovlist ishlovref="DRESOLUTION" activityfilter="active" />
          </valuelist>
        </typepulldown>
        <mandatory />
      </ishfrmfield>
      <ishfrmfield name="SourceLanguageField" ishfieldref="FSOURCELANGUAGE" level="lng" ishcondition="ISHType in ('ISHIllustration', 'ISHMasterDoc', 'ISHModule', 'ISHLibrary')">
        <label resourceref="FSOURCELANGUAGE.Label">Source language</label>
        <description resourceref="FSOURCELANGUAGE.Description">The language that is used as source to translate the XML file to other languages.</description>
        <typelabel />
        <value overwrite="yes" ishcondition="ChangeMode in ('NewVersion', 'Create')" />
      </ishfrmfield>
      <ishfrmfield name="CommentsField" ishfieldref="FCOMMENTS" level="lng" ishcondition="ISHType in ('ISHIllustration', 'ISHMasterDoc', 'ISHModule', 'ISHLibrary')">
        <label resourceref="FCOMMENTS.Label">&amp;Comments</label>
        <description resourceref="FCOMMENTS.Description">Additional free text information.</description>
        <typemultilinetext />
        <value overwrite="yes" ishcondition="ChangeMode in ('NewVersion', 'Create')" />
      </ishfrmfield>
    </ishfrmgroup>
    <ishfrmgroup>
      <label resourceref="ContentGroup.Label">Content</label>
      <ishfrmfield name="FileUploadField" ishfieldref="DISHDOCUMENT" level="compute">
        <typecustom />
      </ishfrmfield>
    </ishfrmgroup>
  </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.CreateLanguageObjectForm']"
    AppendChild $document "//*/ishfrm[@id='Test.CreateLanguageObjectForm']" "//*/ishfrms" $form

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-UpdateLanguageObjectForm
{
    Write-Verbose "Set form 'Test.UpdateLanguageObjectForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.UpdateLanguageObjectForm">
        <ishfrmgroup ref="WorkflowGroup" />
        <ishfrmgroup>
          <label resourceref="ContentGroup.Label">Content</label>
          <ishfrmfield name="FileUploadField" ishfieldref="DISHDOCUMENT" level="compute">
            <typecustom />
          </ishfrmfield>
        </ishfrmgroup>
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.UpdateLanguageObjectForm']"
    AppendChild $document "//*/ishfrm[@id='Test.UpdateLanguageObjectForm']" "//*/ishfrms" $form 

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-CreateObjectForm
{
    Write-Verbose "Set form 'Test.CreateObjectForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.CreateObjectForm">
        <ishfrmgroup>
          <label resourceref="GeneralGroup.Label">General</label>
          <ishfrmfield ref="TitleFieldMock" />
          <ishfrmfield ref="IllustrationTypeFieldMock" />
          <ishfrmfield ref="LibraryTypeFieldMock" />
          <ishfrmfield ref="MasterTypeFieldMock" />
          <ishfrmfield ref="ModuleTypeFieldMock" />
          <ishfrmfield ref="DescriptionFieldMock" />
        </ishfrmgroup>
        <ishfrmgroup ref="TranslationManagementGroup" />
        <ishfrmgroup ref="VersionGroupMock" column="1"/>
        <ishfrmfield ref="ImageLanguageField" />
        <ishfrmfield id="StatusFieldMock" name="StatusFieldMock" ishfieldref="FSTATUS" level="lng">
            <label resourceref="FSTATUS.Label">&amp;Status</label>
            <description resourceref="FSTATUS.Description">Indicator of the progress of the object.</description>
            <typetaglist>
              <autosuggest>
                <valuelist>
                  <lovlist ishlovref="DSTATUS" activityfilter="active" />
                </valuelist>
              </autosuggest>
              <structureview>
                <valuelist>
                  <lovlist ishlovref="DSTATUS" activityfilter="active" />
                </valuelist>
              </structureview>
              <valuepanel>
                <valuelist>
                  <lovlist ishlovref="DSTATUS" activityfilter="active" />
                </valuelist>
              </valuepanel>
            </typetaglist>
            <multivalue />
        </ishfrmfield>
        <ishfrmfield id="AuthorFieldMock" name="AuthorFieldMock" ishfieldref="FAUTHOR" level="lng">
            <label resourceref="FAUTHOR.Label">&amp;Author</label>
            <description resourceref="FAUTHOR.Description">Name of the author.</description>
            <typetaglist>
              <autosuggest>
                <valuelist ref="ActiveAuthorList" />
              </autosuggest>
              <structureview>
                <valuelist ref="ActiveAuthorList" />
              </structureview>
              <valuepanel>
                <valuelist ref="ActiveAuthorList" />
              </valuepanel>
            </typetaglist>
            <multivalue />
        </ishfrmfield>
        <ishfrmfield id="ReviewerFieldMock" name="ReviewerFieldMock" ishfieldref="FREVIEWER" level="lng" ishcondition="ISHType in ('ISHIllustration', 'ISHMasterDoc', 'ISHModule', 'ISHLibrary')">
          <label resourceref="FREVIEWER.Label">&amp;Reviewer</label>
          <description resourceref="FREVIEWER.Description">Name of the reviewer.</description>
          <typepulldown>
            <valuelist ref="ActiveReviewerList" />
          </typepulldown>
        </ishfrmfield>
        <ishfrmfield id="TranslatorFieldMock"  name="TranslatorFieldMock" ishfieldref="FTRANSLATOR" level="lng" ishcondition="ISHType in ('ISHIllustration', 'ISHMasterDoc', 'ISHModule', 'ISHLibrary')">
          <label resourceref="FTRANSLATOR.Label">&amp;Translator</label>
          <description resourceref="FTRANSLATOR.Description">Name of the translator.</description>
          <typepulldown>
            <valuelist ref="ActiveTranslatorList" />
          </typepulldown>
        </ishfrmfield>
        <ishfrmfield id="LastModifiedByFieldMock" name="LastModifiedByFieldMock" ishfieldref="FISHLASTMODIFIEDBY" level="lng" ishcondition="ISHType in ('ISHIllustration', 'ISHMasterDoc', 'ISHModule', 'ISHLibrary')">
          <label resourceref="FISHLASTMODIFIEDBY.Label">Last modified by</label>
          <description resourceref="FISHLASTMODIFIEDBY.Description">Name of the user which has done the last modification to the document.</description>
          <typelabel />
          <readonly />
          <value overwrite="yes" ishcondition="ChangeMode in ('NewVersion', 'Create')" />
        </ishfrmfield>
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.CreateObjectForm']"
    AppendChild $document "//*/ishfrm[@id='Test.CreateObjectForm']" "//*/ishfrms" $form

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-UpdateObjectForm
{
    Write-Verbose "Set form 'Test.UpdateObjectForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.UpdateObjectForm">
        <ishfrmgroup>
          <label resourceref="GeneralGroup.Label">General</label>
          <ishfrmfield ref="TitleFieldMock" />
          <ishfrmfield ref="IdFieldMock" />
          <ishfrmfield ref="IllustrationTypeFieldMock" />
          <ishfrmfield ref="LibraryTypeFieldMock" />
          <ishfrmfield ref="MasterTypeFieldMock" />
          <ishfrmfield ref="ModuleTypeFieldMock" />
          <ishfrmfield ref="DescriptionFieldMock" />
        </ishfrmgroup>
        <ishfrmgroup ref="TranslationManagementGroupMock" />
        <ishfrmgroup ref="VersionGroupMock" />
        <ishfrmgroup ref="WorkflowGroup" />
        <ishfrmgroup>
          <label resourceref="ContentGroup.Label">Content</label>
          <ishfrmfield name="FileUploadField" ishfieldref="DISHDOCUMENT" level="compute">
            <typecustom />
          </ishfrmfield>
        </ishfrmgroup>
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.UpdateObjectForm']"
    AppendChild $document "//*/ishfrm[@id='Test.UpdateObjectForm']" "//*/ishfrms" $form 

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-CreateLogicalPublicationForm
{
    Write-Verbose "Set form 'Test.CreateLogicalPublicationForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.CreateLogicalPublicationForm">
        <ishfrmgroup>
          <label resourceref="GeneralGroup.Label">General</label>
          <ishfrmfield ref="TitleFieldMock" />
          <ishfrmfield id="PublicationTypeFieldMock" name="PublicationTypeFieldMock" ishfieldref="FISHPUBLICATIONTYPE" level="logical">
            <label resourceref="FISHPUBLICATIONTYPE.Label">&amp;Publication type</label>
            <description resourceref="FISHPUBLICATIONTYPE.Description">Indicates the content type of the publication.</description>
            <typepulldown>
              <valuelist>
                <lovlist ishlovref="DPUBLICATIONTYPE" activityfilter="active" />
              </valuelist>
            </typepulldown>
          </ishfrmfield>
          <ishfrmfield id="PublicationProductFamilyNameFieldMock" name="PublicationProductFamilyNameFieldMock" ishfieldref="FISHPRODUCTFAMILYNAME" level="logical">
            <label resourceref="FISHPRODUCTFAMILYNAME.Label">&amp;Product family name</label>
            <description resourceref="FISHPRODUCTFAMILYNAME.Description">The publication's product family name used over local LOVs by DXA-for-DynamicDelivery/DDWebApp such as e.g. 'Tridion Docs'</description>
            <typetaglist>
              <autosuggest>
                <valuelist>
                  <lovlist ishlovref="DPRODUCTFAMILYNAME" activityfilter="active" />
                </valuelist>
              </autosuggest>
              <structureview>
                <valuelist>
                  <lovlist ishlovref="DPRODUCTFAMILYNAME" activityfilter="active" />
                </valuelist>
              </structureview>
              <valuepanel>
                <valuelist>
                  <lovlist ishlovref="DPRODUCTFAMILYNAME" activityfilter="active" />
                </valuelist>
              </valuepanel>
            </typetaglist>
            <multivalue />
          </ishfrmfield>
          <ishfrmfield ref="DescriptionFieldMock" />
        </ishfrmgroup>
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.CreateLogicalPublicationForm']"
    AppendChild $document "//*/ishfrm[@id='Test.CreateLogicalPublicationForm']" "//*/ishfrms" $form

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-UpdateLogicalPublicationForm
{
    Write-Verbose "Set form 'Test.UpdateLogicalPublicationForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.UpdateLogicalPublicationForm">
        <ishfrmgroup>
          <label resourceref="GeneralGroup.Label">General</label>
          <ishfrmfield ref="TitleFieldMock" />
          <ishfrmfield ref="IdFieldMock" />
          <ishfrmfield ref="PublicationTypeFieldMock" />
          <ishfrmfield ref="PublicationProductFamilyNameFieldMock" />
          <ishfrmfield ref="DescriptionFieldMock" />
        </ishfrmgroup>
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.UpdateLogicalPublicationForm']"
    AppendChild $document "//*/ishfrm[@id='Test.UpdateLogicalPublicationForm']" "//*/ishfrms" $form 

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-CreateVersionPublicationForm
{
    Write-Verbose "Set form 'Test.CreateVersionPublicationForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.CreateVersionPublicationForm">
        <ishfrmgroup>
          <label resourceref="VersionGroup.Label">Version</label>
          <ishfrmfield ref="VersionField" />
          <ishfrmfield ref="ChangesField" />
          <ishfrmfield name="PublicationMasterField" ishfieldref="FISHMASTERREF" level="version">
            <label resourceref="FISHMASTERREF.Label">Map</label>
            <description resourceref="FISHMASTERREF.Description">Map used by the publication.</description>
            <typereference assist="yes">
              <selectabletypes>
                <type>ISHMasterDoc</type>
              </selectabletypes>
            </typereference>
          </ishfrmfield>
          <ishfrmfield name="PublicationResourcesField" ishfieldref="FISHRESOURCES" level="version">
            <label resourceref="FISHRESOURCES.Label">Resources</label>
            <description resourceref="FISHRESOURCES.Description">Resources used by the publication.</description>
            <typereference assist="yes">
              <selectabletypes>
                <type>ISHIllustration</type>
                <type>ISHLibrary</type>
                <type>ISHMasterDoc</type>
                <type>ISHModule</type>
                <type>ISHTemplate</type>
              </selectabletypes>
            </typereference>
          </ishfrmfield>
          <ishfrmfield id="PublicationBaselineField" name="PublicationBaselineField" ishfieldref="FISHBASELINE" level="version">
            <label resourceref="FISHBASELINE.Label">&amp;Baseline</label>
            <description resourceref="FISHBASELINE.Description">Baseline used in the publication.</description>
            <typetaglist ishcondition="ChangeMode = 'Update' and ISHType = 'ISHPublication'">
              <autosuggest>
                <valuelist ref="ActiveBaselineList" />
              </autosuggest>
              <structureview>
                <valuelist ref="ActiveBaselineList" />
              </structureview>
              <valuepanel>
                <valuelist ref="ActiveBaselineList" />
              </valuepanel>
            </typetaglist>
            <hidden ishcondition="ChangeMode in ('NewVersion', 'Create') and ISHType = 'ISHPublication'" />
            <mandatory ishcondition="ChangeMode = 'Update' and ISHType = 'ISHPublication'" />
            <readonly ishcondition="ISHType = 'ISHPublicationOutput' or IsReleased='true'" />
            <value overwrite="yes" ishcondition="ChangeMode in ('NewVersion', 'Create') and ISHType = 'ISHPublication'" />
          </ishfrmfield>
          <ishfrmfield id="PublicationContextField" name="PublicationContextField" ishfieldref="FISHPUBCONTEXT" level="version" ishcondition="ChangeMode in ('NewVersion', 'Create')">
            <label resourceref="FISHPUBCONTEXT.Label">Context</label>
            <description resourceref="FISHPUBCONTEXT.Description">The publication context defines which conditional sections will be published.</description>
            <typelabel />
            <hidden />
          </ishfrmfield>
          <ishfrmfield id="PublicationProductReleaseNameField" name="PublicationProductReleaseNameField" ishfieldref="FISHPRODUCTRELEASENAME" level="version">
            <label resourceref="FISHPRODUCTRELEASENAME.Label">&amp;Product release name</label>
            <description resourceref="FISHPRODUCTRELEASENAME.Description">The publication's product release name used over local LOVs by DXA-for-DynamicDelivery/DDWebApp such as e.g. 'Tridion Docs 13 SP1 (13.0.1)'</description>
            <typetaglist>
              <autosuggest>
                <valuelist>
                  <lovlist ishlovref="DPRODUCTRELEASENAME" activityfilter="active" />
                </valuelist>
              </autosuggest>
              <structureview>
                <valuelist>
                  <lovlist ishlovref="DPRODUCTRELEASENAME" activityfilter="active" />
                </valuelist>
              </structureview>
              <valuepanel>
                <valuelist>
                  <lovlist ishlovref="DPRODUCTRELEASENAME" activityfilter="active" />
                </valuelist>
              </valuepanel>
            </typetaglist>
            <multivalue />
          </ishfrmfield>
        </ishfrmgroup>
          <ishfrmgroup id="Publication.EditingOptionsGroup" >
          <label resourceref="EditingOptionsGroup.Label">Editing Options</label>
          <ishfrmfield name="PublicationSourceLanguageField" ishfieldref="FISHPUBSOURCELANGUAGES" level="version">
            <label resourceref="FISHPUBSOURCELANGUAGES.Label">Working &amp;language</label>
            <description resourceref="FISHPUBSOURCELANGUAGES.Description">The language in which you assemble the publication.</description>
            <typelabel ishcondition="ChangeMode = 'Update'" />
            <typepulldown ishcondition="ChangeMode in ('NewVersion', 'Create') and ISHType = 'ISHPublication'">
              <valuelist>
                <lovlist ishlovref="DLANGUAGE" activityfilter="active" />
              </valuelist>
            </typepulldown>
            <mandatory ishcondition="ChangeMode in ('NewVersion', 'Create') and ISHType = 'ISHPublication'" />
            <readonly ishcondition="ChangeMode='Update' or ISHType = 'ISHPublicationOutput'" />
            <value overwrite="yes" ishcondition="ChangeMode in ('NewVersion', 'Create') and ISHType = 'ISHPublication'">
              <var name="defaultlanguage" />
            </value>
          </ishfrmfield>
          <ishfrmfield name="PublicationResolutionField" ishfieldref="FISHREQUIREDRESOLUTIONS" level="version">
            <label resourceref="FISHREQUIREDRESOLUTIONS.Label">Working &amp;resolution</label>
            <description resourceref="FISHREQUIREDRESOLUTIONS.Description">The resolution used for assembling the publication.</description>
            <typepulldown ishcondition="ChangeMode in ('NewVersion', 'Create')">
              <valuelist>
                <lovlist ishlovref="DRESOLUTION" activityfilter="active" />
              </valuelist>
            </typepulldown>
            <typelabel ishcondition="ChangeMode='Update'" />
            <!--mandatory/-->
            <mandatory ishcondition="ChangeMode in ('NewVersion', 'Create')" />
            <readonly ishcondition="ChangeMode='Update'" />
          </ishfrmfield>
        </ishfrmgroup>
        <ishfrmgroup ref="Publication.TranslationManagementGroup" />
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.CreateVersionPublicationForm']"
    AppendChild $document "//*/ishfrm[@id='Test.CreateVersionPublicationForm']" "//*/ishfrms" $form

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-UpdateVersionPublicationForm
{
    Write-Verbose "Set form 'Test.UpdateVersionPublicationForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.UpdateVersionPublicationForm">
        <ishfrmgroup>
          <label resourceref="VersionGroup.Label">Version</label>
          <ishfrmfield ref="VersionField" />
          <ishfrmfield ref="ChangesField" />
          <ishfrmfield name="PublicationMasterField" ishfieldref="FISHMASTERREF" level="version">
            <label resourceref="FISHMASTERREF.Label">Map</label>
            <description resourceref="FISHMASTERREF.Description">Map used by the publication.</description>
            <typereference assist="yes">
              <selectabletypes>
                <type>ISHMasterDoc</type>
              </selectabletypes>
            </typereference>
          </ishfrmfield>
          <ishfrmfield name="PublicationResourcesField" ishfieldref="FISHRESOURCES" level="version">
            <label resourceref="FISHRESOURCES.Label">Resources</label>
            <description resourceref="FISHRESOURCES.Description">Resources used by the publication.</description>
            <typereference assist="yes">
              <selectabletypes>
                <type>ISHIllustration</type>
                <type>ISHLibrary</type>
                <type>ISHMasterDoc</type>
                <type>ISHModule</type>
                <type>ISHTemplate</type>
              </selectabletypes>
            </typereference>
          </ishfrmfield>
          <ishfrmfield ref="PublicationBaselineField" />
          <ishfrmfield ref="PublicationProductReleaseNameField" />
        </ishfrmgroup>
        <ishfrmgroup ref="Publication.EditingOptionsGroup" />
        <ishfrmgroup ref="Publication.TranslationManagementGroup" />
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.UpdateVersionPublicationForm']"
    AppendChild $document "//*/ishfrm[@id='Test.UpdateVersionPublicationForm']" "//*/ishfrms" $form

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-CreateLanguagePublicationForm
{
    Write-Verbose "Set form 'Test.CreateLanguagePublicationForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.CreateLanguagePublicationForm">
        <ishfrmgroup ref="PublicationOutput.GeneralGroup" />
        <ishfrmgroup ref="PublicationOutput.LanguageSettingsGroup" />
        <ishfrmgroup ref="PublicationOutput.ReviewSettingsGroup" />
        <ishfrmgroup ref="PublicationOutput.DraftOptionsGroup" ishcondition="OutputFormat in ('PDF (A4 Manual)', 'PDF (A5 Booklet)', 'PDF (letter Manual)', 'PDF (XPP A4)', 'PDF (XPP A5)', 'PDF (XPP letter)')" />
        <ishfrmgroup ref="PublicationOutput.SDLXPPOptionsGroup" ishcondition="OutputFormat in ('PDF (XPP A4)', 'PDF (XPP A5)', 'PDF (XPP letter)')" />
        <ishfrmgroup ref="PublicationOutput.SDLDITADeliveryOptionsGroup" ishcondition="OutputFormat in ('DITA Delivery')" />
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.CreateLanguagePublicationForm']"
    AppendChild $document "//*/ishfrm[@id='Test.CreateLanguagePublicationForm']" "//*/ishfrms" $form

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-UpdateLanguagePublicationForm
{
    Write-Verbose "Set form 'Test.UpdateLanguagePublicationForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.UpdateLanguagePublicationForm">
        <ishfrmgroup ref="PublicationOutput.GeneralGroup" />
        <ishfrmgroup ref="PublicationOutput.WorkflowGroup" />
        <ishfrmgroup ref="PublicationOutput.LanguageSettingsGroup" />
        <ishfrmgroup ref="PublicationOutput.ReviewSettingsGroup" />
        <ishfrmgroup ref="PublicationOutput.DraftOptionsGroup" ishcondition="OutputFormat in ('PDF (A4 Manual)', 'PDF (A5 Booklet)', 'PDF (letter Manual)', 'PDF (XPP A4)', 'PDF (XPP A5)', 'PDF (XPP letter)')" />
        <ishfrmgroup ref="PublicationOutput.SDLXPPOptionsGroup" ishcondition="OutputFormat in ('PDF (XPP A4)', 'PDF (XPP A5)', 'PDF (XPP letter)')" />
        <ishfrmgroup ref="PublicationOutput.SDLDITADeliveryOptionsGroup" ishcondition="OutputFormat in ('DITA Delivery')" />
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.UpdateLanguagePublicationForm']"
    AppendChild $document "//*/ishfrm[@id='Test.UpdateLanguagePublicationForm']" "//*/ishfrms" $form 

    Save-MetadataConfiguration $document $metadataConfigPath
}

function Set-CreatePublicationForm
{
    Write-Verbose "Set form 'Test.CreatePublicationForm'."

    $document = Get-MetadataConfiguration $metadataConfigPath

    $form = @"
      <ishfrm id="Test.CreatePublicationForm">
        <ishfrmgroup>
          <label resourceref="GeneralGroup.Label">General</label>
          <ishfrmfield ref="TitleFieldMock" />
          <ishfrmfield ref="PublicationTypeFieldMock" />
          <ishfrmfield ref="PublicationProductFamilyNameFieldMock" />
          <ishfrmfield ref="DescriptionFieldMock" />
        </ishfrmgroup>
        <ishfrmgroup>
          <label resourceref="VersionGroup.Label">Version</label>
          <ishfrmfield ref="VersionField" />
          <ishfrmfield ref="ChangesField" />
          <ishfrmfield name="PublicationMasterField" ishfieldref="FISHMASTERREF" level="version">
            <label resourceref="FISHMASTERREF.Label">Map</label>
            <description resourceref="FISHMASTERREF.Description">Map used by the publication.</description>
            <typereference assist="yes">
              <selectabletypes>
                <type>ISHMasterDoc</type>
              </selectabletypes>
            </typereference>
          </ishfrmfield>
          <ishfrmfield name="PublicationResourcesField" ishfieldref="FISHRESOURCES" level="version">
            <label resourceref="FISHRESOURCES.Label">Resources</label>
            <description resourceref="FISHRESOURCES.Description">Resources used by the publication.</description>
            <typereference assist="yes">
              <selectabletypes>
                <type>ISHIllustration</type>
                <type>ISHLibrary</type>
                <type>ISHMasterDoc</type>
                <type>ISHModule</type>
                <type>ISHTemplate</type>
              </selectabletypes>
            </typereference>
          </ishfrmfield>
          <ishfrmfield ref="PublicationBaselineField" />
          <ishfrmfield ref="PublicationContextField" />
          <ishfrmfield ref="PublicationProductReleaseNameField" />
        </ishfrmgroup>
        <ishfrmgroup ref="Publication.EditingOptionsGroup" />
        <ishfrmgroup ref="Publication.TranslationManagementGroup" />
        <ishfrmgroup ref="PublicationOutput.GeneralGroup" />
        <ishfrmgroup ref="PublicationOutput.LanguageSettingsGroup" />
        <ishfrmgroup ref="PublicationOutput.ReviewSettingsGroup" />
      </ishfrm>
"@

    RemoveChild $document "//*/ishfrm[@id='Test.CreatePublicationForm']"
    AppendChild $document "//*/ishfrm[@id='Test.CreatePublicationForm']" "//*/ishfrms" $form

    Save-MetadataConfiguration $document $metadataConfigPath
}

Set-CreateLogicalObjectForm
Set-UpdateLogicalObjectForm
Set-CreateVersionObjectForm
Set-UpdateVersionObjectForm
Set-CreateLanguageObjectForm
Set-UpdateLanguageObjectForm
Set-CreateObjectForm
Set-UpdateObjectForm

Set-CreateLogicalPublicationForm
Set-UpdateLogicalPublicationForm
Set-CreateVersionPublicationForm
Set-UpdateVersionPublicationForm
Set-CreateLanguagePublicationForm
Set-UpdateLanguagePublicationForm
Set-CreatePublicationForm