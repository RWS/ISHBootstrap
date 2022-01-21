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
    Configure deployment configuration custom parameters for project/stage.
.DESCRIPTION
    This cmdlet adds custom configuration entries that can be used during recipe execution.
.PARAMETER ConfigFilePath
    Path to json configuration file.
.PARAMETER ISHBootstrapVersion
    Version of ISHBootstrap module.
.PARAMETER Project
    A project name. Indicates how this configuration will be referenced in a recipe.
.PARAMETER Stage
    Stage of a project. (e.g. Dev, Test, Prod, etc.)
    Similar to project will be used as a part of configuration reference in recipe.
.PARAMETER Key
    New configuration key name.
.PARAMETER Value
    Configuration key value.
.PARAMETER FilePath
    Path to the file where configuration value is stored. Fore example certificate private key.
.PARAMETER ISHDeployment
    Specifies the name or instance of the Content Manager deployment. See Get-ISHDeployment for more details.
#>
Function Set-ISHDeploymentCustomConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = "Single Key/Value")]
        [Parameter(Mandatory = $false, ParameterSetName = "File Key/Blob")]
        [ValidateScript( { Test-Path $_ })]
        [string]$ConfigFilePath,
        [Parameter(Mandatory = $true, ParameterSetName = "Single Key/Value")]
        [Parameter(Mandatory = $true, ParameterSetName = "File Key/Blob")]
        [string]$ISHBootstrapVersion,
        [Parameter(Mandatory = $true, ParameterSetName = "Single Key/Value")]
        [Parameter(Mandatory = $true, ParameterSetName = "File Key/Blob")]
        [string]$Project,
        [Parameter(Mandatory = $true, HelpMessage = "The Tridion Docs stage (environment), e.g. Development, Acceptance, Production", ParameterSetName = "Single Key/Value")]
        [Parameter(Mandatory = $true, HelpMessage = "The Tridion Docs stage (environment), e.g. Development, Acceptance, Production", ParameterSetName = "File Key/Blob")]
        [string]$Stage,
        [Parameter(Mandatory = $true, ParameterSetName = "Single Key/Value")]
        [Parameter(Mandatory = $true, ParameterSetName = "File Key/Blob")]
        [string]$Key,
        [Parameter(Mandatory = $false, ParameterSetName = "Single Key/Value")]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Value = $null,
        [Parameter(Mandatory = $true, ParameterSetName = "File Key/Blob")]
        [ValidateScript( { Test-Path $_ })]
        [string]$FilePath,
        [Parameter(Mandatory = $false, ParameterSetName = "Single Key/Value")]
        [Parameter(Mandatory = $false, ParameterSetName = "File Key/Blob")]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
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

        if ($PSCmdlet.ParameterSetName -eq 'File Key/Blob') {
            $Text = Get-Content -Raw -Path $FilePath
            $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
            $Value = [Convert]::ToBase64String($Bytes)
        }
        if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Custom) {
            $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH | Add-Member -MemberType NoteProperty -Name Custom -Value ([pscustomobject]@{$Key = $Value })
        }
        elseif ($keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Custom.$Key) {
            $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Custom.$Key = $Value
        }
        else {
            $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Custom | Add-Member -MemberType NoteProperty -Name $Key -Value ([string]$Value)
        }

        ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFilePath
        Write-Verbose "Updated $ConfigFilePath"
    }

    end {

    }
}
