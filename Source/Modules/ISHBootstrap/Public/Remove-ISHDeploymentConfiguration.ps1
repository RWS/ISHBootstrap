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
   Remove deployment configuration stage.
.DESCRIPTION
   Removes selected stage from deployment configuration file.
.PARAMETER ConfigFilePath
   Path to json configuration file from which configuration section will be removed.
.PARAMETER ISHBootstrapVersion
   Version of ISHBootstrap module that specified in configuration.
.PARAMETER Project
   A project name where deployment configuration is located.
.PARAMETER Stage
   Name of a stage which will be removed.
.EXAMPLE
   Remove-ISHDeploymentConfiguration -ConfigFilePath configfilepath -ISHBootstrapVersion 2.0 -Project project -Stage stage
#>
Function Remove-ISHDeploymentConfiguration {
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
         Write-Verbose "Project/Stage $Project/$Stage does not exist."
      }
      else {
         $keyValues.$ISHBootstrapVersion.Project.$Project.PSObject.Properties.Remove($Stage)

         ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFilePath -Force
         Write-Verbose "Updated $ConfigFilePath"
      }
   }

   end {

   }
}
