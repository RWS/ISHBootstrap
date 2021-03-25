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
   Configure database for project/stage
.DESCRIPTION
   Configure database for project/stage
.EXAMPLE
   Set-ISHDeploymentConfiguration -ConfigFile cofigfile -ISBootstrapVersion 2.0 -Project project -Stage stage
.EXAMPLE
   Set-ISHDeploymentConfiguration -ConfigFile cofigfile -ISBootstrapVersion 2.0 -Project project -Stage stage -DataSource datasource -InitialCatalog db -Username user -Password pass -Type sqlserver2017
#>
Function Set-ISHDeploymentConfiguration {
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
        [string]$DataSource = $(Get-ISHDeploymentParameters -Name databasesource).Value,
        [Parameter(Mandatory = $false)]
        [string]$InitialCatalog = $(Get-ISHDeploymentParameters -Name databasename).Value,
        [Parameter(Mandatory = $false)]
        [string]$Username = $(Get-ISHDeploymentParameters -Name databaseuser).Value,
        [Parameter(Mandatory = $false)]
        [string]$Password = $(Get-ISHDeploymentParameters -Name databasepassword -ShowPassword).Value,
        [Parameter(Mandatory = $false)]
        [string]$Type = "sqlserver2017"
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

        $dbKV = @{
            DataSource     = $DataSource
            InitialCatalog = $InitialCatalog
            Username       = $Username
            Password       = $Password
            Type           = $Type
        }

        $path = $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH
        foreach ($i in @('Integration', 'Database', 'SQLServer')) {
            if (-not $path.$i) {
                $path | Add-Member -MemberType NoteProperty -Name $i -Value ([pscustomobject]@{ })
            }
            $path = $path.$i
        }
        $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH.Integration.Database.SQLServer = $dbKV

        ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFile
        Write-Verbose "Updated $ConfigFile"

        Set-Tag -Name "CodeVersion" -Value $ISBootstrapVersion
        Set-Tag -Name "Project" -Value $Project
        Set-Tag -Name "Stage" -Value $Stage
    }

    end {

    }
}
