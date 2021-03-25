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
   Configure the components for project/stage
.DESCRIPTION
   Configure the components for project/stage
.EXAMPLE
   Set-ISHDeploymentComponentConfiguration -ConfigFile cofigfile -ISBootstrapVersion 2.0 -Project project -Stage stage
#>
Function Set-ISHDeploymentComponentConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [string]$ConfigFile,
        [Parameter(Mandatory = $true)]
        [string]$ISBootstrapVersion,
        [Parameter(Mandatory = $true)]
        [string]$Project,
        [Parameter(Mandatory = $true)]
        [string]$Stage
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

        $componentsKV = [pscustomobject]@{
            "BackgroundTask-Publish" = @{Count = 1 }
            "BackgroundTask-Single"  = @{Count = 1 }
            "BackgroundTask-Multi"   = @{Count = 1 }
            Crawler                  = @{Count = 1 }
            TranslationBuilder       = @{Count = 1 }
            TranslationOrganizer     = @{Count = 1 }
        }

        if (-not $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH.Component) {
            $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH | Add-Member -MemberType NoteProperty -Name Component -Value $componentsKV
        }
        else {
            $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH.Component = $componentsKV
        }

        ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFile
        Write-Verbose "Updated $ConfigFile"
    }

    end {

    }
}
