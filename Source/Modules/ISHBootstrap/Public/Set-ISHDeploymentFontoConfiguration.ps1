<#
# Copyright (c) 2021 All Rights Reserved by the SDL Group.
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
   Configure the Fonto integration for project/stage
.DESCRIPTION
   Configure the Fonto integration for project/stage
.EXAMPLE
   Set-ISHDeploymentFontoConfiguration -Project project -Stage stage
.EXAMPLE
   Set-ISHDeploymentFontoConfiguration -ConfigFile cofigfile -ISBootstrapVersion 2.0 -Project project -Stage stage -DraftSpace -DocumentHistoryForDraftSpace -ReviewSpace
#>
Function Set-ISHDeploymentFontoConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateScript( { Test-Path $_ })]
        [string]$ConfigFile = $((Get-Variable -Name "ISHDeployemntConfigFile").Value),
        [Parameter(Mandatory = $false)]
        [string]$ISBootstrapVersion = "ISHBootstrap.2.0.0",
        [Parameter(Mandatory = $true)]
        [string]$Project,
        [Parameter(Mandatory = $true)]
        [string]$Stage,
        [Parameter(Mandatory = $false)]
        [switch]$DraftSpace,
        [Parameter(Mandatory = $false)]
        [ValidateScript( { $DraftSpace.IsPresent })]
        [switch]$DocumentHistoryForDraftSpace,
        [Parameter(Mandatory = $false)]
        [switch]$ReviewSpace
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $keyValues = Get-Content -Raw -Path $ConfigFile | ConvertFrom-Json
        Write-Verbose "Reed $ConfigFile"
        if (-not $keyValues.$ISBootstrapVersion.Project.$Project.$Stage ) {
            throw "Project/Stage $Project/$Stage does not exist. Use New-Project.ps1"
        }

        $FONTO = [pscustomobject]@{ }
        if ($DraftSpace.IsPresent) {
            if ($DocumentHistoryForDraftSpace.IsPresent) {
                $ds = @{
                    DocumentHistoryForDraftSpace = $null
                }
            }
            else {
                $ds = $null
            }
            $FONTO | Add-Member -MemberType NoteProperty -Name DraftSpace -Value $ds
        }

        if ($ReviewSpace.IsPresent) {
            $FONTO | Add-Member -MemberType NoteProperty -Name ReviewSpace -Value $null
        }

        if (-not $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH.Integration.FONTO) {
            $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH.Integration | Add-Member -MemberType NoteProperty -Name FONTO -Value $FONTO
        }
        else {
            $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH.Integration.FONTO = $FONTO
        }

        ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFile
        Write-Verbose "Updated $ConfigFile"
    }

    end {

    }
}
