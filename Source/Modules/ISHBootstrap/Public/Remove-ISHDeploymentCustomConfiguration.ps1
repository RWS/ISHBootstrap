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
   Removes Deployment configuration (project/stage) custom values
.DESCRIPTION
   Removes Deployment configuration (project/stage) custom values
#>
Function Remove-ISHDeploymentCustomConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Root")]
        [Parameter(Mandatory = $true, ParameterSetName = "Key")]
        [ValidateScript( { Test-Path $_ })]
        [string]$ConfigFile,
        [Parameter(Mandatory = $true, ParameterSetName = "Root")]
        [Parameter(Mandatory = $true, ParameterSetName = "Key")]
        [string]$ISBootstrapVersion,
        [Parameter(Mandatory = $true, ParameterSetName = "Root")]
        [Parameter(Mandatory = $true, ParameterSetName = "Key")]
        [string]$Project,
        [Parameter(Mandatory = $true, ParameterSetName = "Root")]
        [Parameter(Mandatory = $true, ParameterSetName = "Key")]
        [string]$Stage,
        [Parameter(Mandatory = $true, ParameterSetName = "Key")]
        [string]$Key
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $keyValues = Get-Content -Raw -Path $ConfigFile | ConvertFrom-Json
        Write-Verbose "Reed existing $ConfigFile"
        if (-not $keyValues.$ISBootstrapVersion.Project.$Project.$Stage) {
            Write-Verbose "Project/Stage $Project/$Stage does not exist."
        }
        else {
            switch ($PSCmdlet.ParameterSetName) {
                'Root' {
                    $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH.PSObject.Properties.Remove('Custom')
                }
                'Key' {
                    $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH.Custom.PSObject.Properties.Remove($Key)
                }
            }
        }
        ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFile
        Write-Verbose "Updated $ConfigFile"
    }

    end {

    }
}
