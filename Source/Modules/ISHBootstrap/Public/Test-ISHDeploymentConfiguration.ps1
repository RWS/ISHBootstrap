<#
# Copyright (c) 2021 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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
   Validate Deployment configuration (project/stage).
.DESCRIPTION
   Validate that all required Deployment configuration parameters are present in configuration file.
.EXAMPLE
   Test-ISHDeploymentConfiguration -ConfigFilePath ConfigFilePath -ISHBootstrapVersion 2.0 -Project project -Stage stage
#>
Function Test-ISHDeploymentConfiguration {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [ValidateScript( { Test-Path $_ })]
      [string]$ConfigFilePath,
      [Parameter(Mandatory = $true)]
      [string]$ISHBootstrapVersion,
      [Parameter(Mandatory = $true)]
      [string]$Project,
      [Parameter(Mandatory = $true, HelpMessage = "The Tridion Docs stage (environment), e.g. Development, Acceptance, Production")]
      [string]$Stage
   )

   begin {
      Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
      foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
   }

   process {
      $keyValues = Get-Content -Raw -Path $ConfigFilePath | ConvertFrom-Json
      Write-Verbose "Reed existing $ConfigFilePath"
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage) {
         throw "Project/Stage $Project/$Stage does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.Description) {
         throw "Key $Project/$Stage/Description does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.Hostname) {
         throw "Key $Project/$Stage/Hostname does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH) {
         throw "Key $Project/$Stage/ISH does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.ProductVersion) {
         throw "Key $Project/$Stage/ISH/ProductVersion does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Integration) {
         throw "Key $Project/$Stage/ISH/Integration does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Integration.Database) {
         throw "Key $Project/$Stage/ISH/Integration/Database does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Integration.Database.SQLServer) {
         throw "Key $Project/$Stage/ISH/Integration/Database/SQLServer does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Integration.Database.SQLServer.DataSource) {
         throw "Key $Project/$Stage/ISH/Integration/Database/SQLServer/DataSource does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Integration.Database.SQLServer.InitialCatalog) {
         throw "Key $Project/$Stage/ISH/Integration/Database/SQLServer/InitialCatalog does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Integration.Database.SQLServer.Username) {
         throw "Key $Project/$Stage/ISH/Integration/Database/SQLServer/Username does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Integration.Database.SQLServer.Password) {
         throw "Key $Project/$Stage/ISH/Integration/Database/SQLServer/Password does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Integration.Database.SQLServer.Type) {
         throw "Key $Project/$Stage/ISH/Integration/Database/SQLServer/Type does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component) {
         throw "Key $Project/$Stage/ISH/Component does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component."Single") {
         throw "Key $Project/$Stage/ISH/Component/Single does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component."Single".Count) {
         throw "Key $Project/$Stage/ISH/Component/Single/Count does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component."Publish") {
         throw "Key $Project/$Stage/ISH/Component/Publish does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component."Publish".Count) {
         throw "Key $Project/$Stage/ISH/Component/Publish/Count does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component."BackgroundTask-Multi") {
         throw "Key $Project/$Stage/ISH/Component/BackgroundTask-Multi does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component."BackgroundTask-Multi".Count) {
         throw "Key $Project/$Stage/ISH/Component/BackgroundTask-Multi/Count does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component."Crawler") {
         throw "Key $Project/$Stage/ISH/Component/Crawler does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component."Crawler".Count) {
         throw "Key $Project/$Stage/ISH/Component/Crawler/Count does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component."TranslationBuilder") {
         throw "Key $Project/$Stage/ISH/Component/TranslationBuilder does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component."TranslationBuilder".Count) {
         throw "Key $Project/$Stage/ISH/Component/TranslationBuilder/Count does not exist."
      }if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component."TranslationOrganizer") {
         throw "Key $Project/$Stage/ISH/Component/TranslationOrganizer does not exist."
      }
      if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Component."TranslationOrganizer".Count) {
         throw "Key $Project/$Stage/ISH/Component/TranslationOrganizer/Count does not exist."
      }
   }
   end {

   }
}
