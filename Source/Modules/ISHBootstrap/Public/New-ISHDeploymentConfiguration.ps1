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
    Create a new Deployment configuration (project/stage)
.DESCRIPTION
    This cmdlet creates a new deployment configuration section in configration file provided by ConfigFilePath parameter.
    The deployment configuration created provides basic configuration options for product deployment.
.PARAMETER ConfigFilePath
    Path to json configuration file where new configuration section will be created.
.PARAMETER ISHBootstrapVersion
    Version of ISHBootstrap module in case any specific version is required.
.PARAMETER Project
    A project name. Indicates how this configuration will be referenced in a recipe.
.PARAMETER Stage
    Stage of a project. (e.g. Dev, Test, Prod, etc.)
    Similar to project will be used as a part of configuration reference in recipe.
.PARAMETER Hostname
    Hostname. By default basehostname form Deployment parameters will be set.
.PARAMETER ISHVersion
    Version of ISHCM. By default softwareversion form Deployment parameters will be set.
.PARAMETER Description
    Deployent configuration description.
.PARAMETER ISHDeployment
    Specifies the name or instance of the Content Manager deployment. See Get-ISHDeployment for more details.
.EXAMPLE
    New-ISHDeploymentConfiguration -ConfigFilePath ConfigFilePath -Project project -Stage stage
#>
Function New-ISHDeploymentConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigFilePath,
        [Parameter(Mandatory = $false)]
        [string]$ISHBootstrapVersion="2.0",
        [Parameter(Mandatory = $true)]
        [string]$Project,
        [Parameter(Mandatory = $true, HelpMessage = "The Tridion Docs stage (environment), e.g. Development, Acceptance, Production")]
        [string]$Stage,
        [Parameter(Mandatory = $false)]
        [string]$Hostname,
        [Parameter(Mandatory = $false)]
        [string]$ISHVersion,
        [Parameter(Mandatory = $false)]
        [string]$Description = $null,
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        if(-not $ConfigFilePath){
            $ConfigFilePath = (Get-Variable -Name "ISHDeploymentConfigFilePath").Value -f ($ISHDeployment  -replace "^InfoShare$")
        }
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
        if(-not $Hostname) {
            $Hostname = Get-ISHDeploymentParameters -Name basehostname -ValueOnly @ISHDeploymentSplat
        }
        if(-not $ISHVersion) {
            $ISHVersion = Get-ISHDeploymentParameters -Name softwareversion -ValueOnly @ISHDeploymentSplat
        }
    }

    process {
        if (-not $Description) {
            $Description = "Deployment stack configuration for project $Project on stage $Stage for hostname $Hostname ."
        }
        Write-Debug "Description=$Description"

        if (Test-Path -Path $ConfigFilePath) {
            $keyValues = Get-Content -Raw -Path $ConfigFilePath | ConvertFrom-Json
            Write-Verbose "Reed existing $ConfigFilePath"
        }
        else {
            $ConfigDir = [System.IO.Path]::GetDirectoryName($ConfigFilePath)
            if (-Not (Test-Path -Path $ConfigDir)) {
                New-Item $ConfigDir -ItemType Directory
            }
            $keyValues = [pscustomobject] @{ }
        }

        $projectStageKV = @{
            Description = $Description
            Hostname    = $Hostname
            ISH         = @{
                ProductVersion = $ISHVersion
                Credentials    = @{
                    ServiceAdmin = @{
                        Password = "admin"
                        Username = "admin"
                    }
                }
            }
        }

        $path = $keyValues
        foreach ($i in @($ISHBootstrapVersion, 'Project', $Project, $Stage)) {
            if (-not $path.$i) {
                $path | Add-Member -MemberType NoteProperty -Name $i -Value ([pscustomobject]@{ })
            }
            $path = $path.$i
        }
        $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage = $projectStageKV
        ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFilePath
        Write-Verbose "Updated $ConfigFilePath"

        $projectStageHash = @{
            ConfigFilePath      = $ConfigFilePath
            ISHBootstrapVersion = $ISHBootstrapVersion
            Project             = $Project
            Stage               = $Stage

        }

        Set-ISHDeploymentConfiguration @projectStageHash @ISHDeploymentSplat
        Set-ISHDeploymentComponentConfiguration @projectStageHash
    }

    end {

    }
}
