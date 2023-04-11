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
    Add database configuration for project/stage.
.DESCRIPTION
    Add new section with database configuration for selected for project/stage.
.PARAMETER ConfigFilePath
    Path to json configuration file.
.PARAMETER ISHBootstrapVersion
    Version of ISHBootstrap module.
.PARAMETER Project
    A project name. Indicates how this configuration will be referenced in a recipe.
.PARAMETER Stage
    Stage of a project. (e.g. Dev, Test, Prod, etc.)
    Similar to project will be used as a part of configuration reference in recipe.
.PARAMETER DataSource
    Database source. By default databasesource deployment parameter will be used.
.PARAMETER InitialCatalog
    Database name. By default databasename deployment parameter will be used.
.PARAMETER Username
    Database user name. By default databaseuser deployment parameter will be used.
.PARAMETER Password
    Database user password. By default databasepassword deployment parameter will be used.
.PARAMETER AmInitialCatalog
    Database name. By default value from ishamconnectstring deployment parameter will be used.
.PARAMETER AmUsername
    Database user name. By default value from ishamconnectstring deployment parameter will be used.
.PARAMETER AmPassword
    Database user password. By default value from ishamconnectstring deployment parameter will be used.
.PARAMETER BffInitialCatalog
    Database name. By default value from ishbffconnectstring deployment parameter will be used.
.PARAMETER BffUsername
    Database user name. By default value from ishbffconnectstring deployment parameter will be used.
.PARAMETER BffPassword
    Database user password. By default value from ishbffconnectstring deployment parameter will be used.
.PARAMETER IdInitialCatalog
    Database name. By default value from ishidconnectstring deployment parameter will be used.
.PARAMETER IdUsername
    Database user name. By default value from ishidconnectstring deployment parameter will be used.
.PARAMETER IdPassword
    Database user password. By default value from ishidconnectstring deployment parameter will be used.
.PARAMETER Type
    Database type. By default databasetype deployment parameter will be used.
.PARAMETER ISHDeployment
    Specifies the name or instance of the Content Manager deployment. See Get-ISHDeployment for more details.
.EXAMPLE
    Set-ISHDeploymentConfiguration -ConfigFilePath configfilepath -ISHBootstrapVersion 2.0 -Project project -Stage stage
.EXAMPLE
    Set-ISHDeploymentConfiguration -ConfigFilePath configfilepath -ISHBootstrapVersion 2.0 -Project project -Stage stage -DataSource datasource -InitialCatalog db -Username user -Password pass -Type sqlserver2017
#>
Function Set-ISHDeploymentConfiguration {
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
        [string]$DataSource,
        [Parameter(Mandatory = $false)]
        [string]$InitialCatalog,
        [Parameter(Mandatory = $false)]
        [string]$Username,
        [Parameter(Mandatory = $false)]
        [string]$Password,
        [Parameter(Mandatory = $false)]
        [string]$AmInitialCatalog,
        [Parameter(Mandatory = $false)]
        [string]$AmUsername,
        [Parameter(Mandatory = $false)]
        [string]$AmPassword,
        [Parameter(Mandatory = $false)]
        [string]$BffInitialCatalog,
        [Parameter(Mandatory = $false)]
        [string]$BffUsername,
        [Parameter(Mandatory = $false)]
        [string]$BffPassword,
        [Parameter(Mandatory = $false)]
        [string]$IdInitialCatalog,
        [Parameter(Mandatory = $false)]
        [string]$IdUsername,
        [Parameter(Mandatory = $false)]
        [string]$IdPassword,
        [Parameter(Mandatory = $false)]
        [string]$Type,
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
        if(-not $DataSource){
            $DataSource = Get-ISHDeploymentParameters -Name databasesource -ValueOnly @ISHDeploymentSplat
        }
        if(-not $InitialCatalog){
            $InitialCatalog = Get-ISHDeploymentParameters -Name databasename -ValueOnly @ISHDeploymentSplat
        }
        if(-not $Username){
            $Username = Get-ISHDeploymentParameters -Name databaseuser -ValueOnly @ISHDeploymentSplat
        }
        if(-not $Password){
            $Password = Get-ISHDeploymentParameters -Name databasepassword -ShowPassword -ValueOnly @ISHDeploymentSplat
        }
        if(-not $Type){
            $Type = Get-ISHDeploymentParameters -Name databasetype -ValueOnly @ISHDeploymentSplat
        }
        if(-not $ConfigFilePath){
            $ConfigFilePath = (Get-Variable -Name "ISHDeploymentConfigFilePath").Value -f ($ISHDeployment  -replace "^InfoShare$")
        }
        $deployment = Get-ISHDeployment @ISHDeploymentSplat
        if ($deployment.SoftwareVersion.Major -ge 15) {
            $ishamconnectstring = Get-ISHDeploymentParameters -Name ishamconnectstring -ValueOnly @ISHDeploymentSplat
            $amdb = New-Object System.Data.Common.DbConnectionStringBuilder
            $amdb.set_ConnectionString($ishamconnectstring)
            $ishbffconnectstring = Get-ISHDeploymentParameters -Name ishbffconnectstring -ValueOnly @ISHDeploymentSplat
            $bffdb = New-Object System.Data.Common.DbConnectionStringBuilder
            $bffdb.set_ConnectionString($ishbffconnectstring)
            $ishidconnectstring = Get-ISHDeploymentParameters -Name ishidconnectstring -ValueOnly @ISHDeploymentSplat
            $iddb = New-Object System.Data.Common.DbConnectionStringBuilder
            $iddb.set_ConnectionString($ishidconnectstring)
            if(-not $AmInitialCatalog -and $Type -eq "sqlserver"){
                $AmInitialCatalog = $amdb.'initial catalog'
            }
            if(-not $AmUsername){
                $AmUsername = $amdb.'user id'
            }
            if(-not $AmPassword){
                $AmPassword = $amdb.password
            }
            if(-not $BffInitialCatalog -and $Type -eq "sqlserver"){
                $BffInitialCatalog = $bffdb.'initial catalog'
            }
            if(-not $BffUsername){
                $BffUsername = $bffdb.'user id'
            }
            if(-not $BffPassword){
                $BffPassword = $bffdb.password
            }
            if(-not $IdInitialCatalog -and $Type -eq "sqlserver"){
                $IdInitialCatalog = $iddb.'initial catalog'
            }
            if(-not $IdUsername){
                $IdUsername = $iddb.'user id'
            }
            if(-not $IdPassword){
                $IdPassword = $iddb.password
            }
        }
    }

    process {
        $keyValues = Get-Content -Raw -Path $ConfigFilePath | ConvertFrom-Json
        Write-Verbose "Reed $ConfigFilePath"
        if (-not $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage ) {
            throw "Project/Stage $Project/$Stage does not exist. Use New-Project.ps1"
        }

        $dbKV = @{
            DataSource     = $DataSource
            InitialCatalog = $InitialCatalog
            Username       = $Username
            Password       = $Password
            Type           = $Type
        }

        if ($deployment.SoftwareVersion.Major -ge 15) {
            $dbKV += @{
                AmInitialCatalog = $AmInitialCatalog
                AmUsername       = $AmUsername
                AmPassword       = $AmPassword
                BffInitialCatalog= $BffInitialCatalog
                BffUsername      = $BffUsername
                BffPassword      = $BffPassword
                IdInitialCatalog = $IdInitialCatalog
                IdUsername       = $IdUsername
                IdPassword       = $IdPassword
            }
        }
        $path = $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH
        foreach ($i in @('Integration', 'Database', 'SQLServer')) {
            if (-not $path.$i) {
                $path | Add-Member -MemberType NoteProperty -Name $i -Value ([pscustomobject]@{ })
            }
            $path = $path.$i
        }
        $keyValues.$ISHBootstrapVersion.Project.$Project.$Stage.ISH.Integration.Database.SQLServer = $dbKV

        ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFilePath
        Write-Verbose "Updated $ConfigFilePath"

        Set-Tag -Name "CodeVersion" -Value $ISHBootstrapVersion @ISHDeploymentSplat
        Set-Tag -Name "Project" -Value $Project @ISHDeploymentSplat
        Set-Tag -Name "Stage" -Value $Stage @ISHDeploymentSplat
    }

    end {

    }
}
