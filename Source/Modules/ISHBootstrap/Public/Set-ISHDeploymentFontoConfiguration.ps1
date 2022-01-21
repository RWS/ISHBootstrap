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
    Add Fonto integration configuration section for project/stage.
.DESCRIPTION
    This cmdlet adds Fonto specific configuration section for selected project and stage.
.PARAMETER ConfigFilePath
    Path to json configuration file.
.PARAMETER ISHBootstrapVersion
    Version of ISHBootstrap module.
.PARAMETER Project
    A project name. Indicates how this configuration will be referenced in a recipe.
.PARAMETER Stage
    Stage of a project. (e.g. Dev, Test, Prod, etc.)
    Similar to project will be used as a part of configuration reference in recipe.
.PARAMETER ISHVersion
    Version of product. By default softwareversion form Deployment parameters will be set.
.PARAMETER DraftSpace
    Enable draft space feature.
.PARAMETER DocumentHistoryForDraftSpace
    Enable document history for draft space feature.
.PARAMETER ReviewSpace
    Enable review space feature.
.PARAMETER DocumentHistoryForReviewSpace
    Enable document history for review space feature.
.PARAMETER ISHDeployment
    Specifies the name or instance of the Content Manager deployment. See Get-ISHDeployment for more details.
.EXAMPLE
    Set-ISHDeploymentFontoConfiguration -Project project -Stage stage
.EXAMPLE
    Set-ISHDeploymentFontoConfiguration -ConfigFilePath configfilepath -ISHBootstrapVersion 2.0 -Project project -Stage stage -DraftSpace -DocumentHistoryForDraftSpace -ReviewSpace -DocumentHistoryForReviewSpace
#>
Function Set-ISHDeploymentFontoConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateScript( { Test-Path $_ })]
        [string]$ConfigFilePath,
        [Parameter(Mandatory = $false)]
        [string]$ISHBootstrapVersion = "2.0",
        [Parameter(Mandatory = $true)]
        [string]$Project,
        [Parameter(Mandatory = $true, HelpMessage = "The Tridion Docs stage (environment), e.g. Development, Acceptance, Production")]
        [string]$Stage,
        [Parameter(Mandatory = $false)]
        [switch]$DraftSpace,
        [Parameter(Mandatory = $false)]
        [ValidateScript( { $DraftSpace.IsPresent })]
        [switch]$DocumentHistoryForDraftSpace,
        [Parameter(Mandatory = $false)]
        [switch]$ReviewSpace,
        [Parameter(Mandatory = $false)]
        [ValidateScript( { $ReviewSpace.IsPresent })]
        [switch]$DocumentHistoryForReviewSpace,
        [Parameter(Mandatory = $false)]
        [string]$ISHVersion,
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
        if(-not $ISHVersion){
            $ISHVersion = Get-ISHDeploymentParameters -Name softwareversion -ValueOnly @ISHDeploymentSplat
        }
        if(-not $ConfigFilePath){
            $ConfigFilePath = (Get-Variable -Name "ISHDeploymentConfigFilePath").Value -f ($ISHDeployment  -replace "^InfoShare$")
        }
    }

    process {
        $keyValues = Get-Content -Raw -Path $ConfigFilePath | ConvertFrom-Json
        Write-Verbose "Reed $ConfigFilePath"
        if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage ) {
            throw "Project/Stage $Project/$Stage does not exist. Use New-Project.ps1"
        }

        $FONTO = [pscustomobject]@{ }
        if ($DraftSpace.IsPresent) {
            $ds = if ($DocumentHistoryForDraftSpace.IsPresent) { @{ DocumentHistoryForDraftSpace = $null } } else { $null }
            $FONTO | Add-Member -MemberType NoteProperty -Name DraftSpace -Value $ds
        }

        if ($ReviewSpace.IsPresent) {
            
            $ds = if ($DocumentHistoryForReviewSpace.IsPresent -and ($ISHVersion -gt (New-Object 'Version' '14.0.3'))) { @{ DocumentHistoryForReviewSpace = $null } } else { $null }
            $FONTO | Add-Member -MemberType NoteProperty -Name ReviewSpace -Value $ds
        }

        if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Integration.FONTO) {
            $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Integration | Add-Member -MemberType NoteProperty -Name FONTO -Value $FONTO
        }
        else {
            $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Integration.FONTO = $FONTO
        }

        ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFilePath
        Write-Verbose "Updated $ConfigFilePath"
    }

    end {

    }
}
