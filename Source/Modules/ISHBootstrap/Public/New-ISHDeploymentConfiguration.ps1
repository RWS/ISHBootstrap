<#
.Synopsis
   Create a new Deployment configuration (project/stage)
.DESCRIPTION
   Create a new Deployment configuration (project/stage)
.EXAMPLE
   New-ISHDeploymentConfiguration -Project project -Stage stage
.EXAMPLE
   New-ISHDeploymentConfiguration -ConfigFile cofigfile -Project project -Stage stage
#>
Function New-ISHDeploymentConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigFile=$((Get-Variable -Name "ISHDeployemntConfigFile").Value),
        [Parameter(Mandatory = $false)]
        [string]$ISBootstrapVersion="ISHBootstrap.2.0.0",
        [Parameter(Mandatory = $true)]
        [string]$Project,
        [Parameter(Mandatory = $true)]
        [string]$Stage,
        [Parameter(Mandatory = $false)]
        [string]$Hostname=$(Get-ISHDeploymentParameters -Name basehostname).Value,
        [Parameter(Mandatory = $false)]
        [string]$ISHVersion=$(Get-ISHDeploymentParameters -Name softwareversion).Value,
        [Parameter(Mandatory = $false)]
        [string]$Description = $null
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        if (-not $Description) {
            $Description = "Deployment stack configuration for project $Project on stage $Stage for hostname $Hostname ."
        }
        Write-Debug "Description=$Description"

        if (Test-Path -Path $ConfigFile) {
            $keyValues = Get-Content -Raw -Path $ConfigFile | ConvertFrom-Json
            Write-Verbose "Reed existing $ConfigFile"
        }
        else {
            $ConfigDir = [System.IO.Path]::GetDirectoryName($ConfigFile)
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
            }
        }

        $path = $keyValues
        foreach ($i in @($ISBootstrapVersion, 'Project', $Project, $Stage)) {
            if (-not $path.$i) {
                $path | Add-Member -MemberType NoteProperty -Name $i -Value ([pscustomobject]@{ })
            }
            $path = $path.$i
        }
        $keyValues.$ISBootstrapVersion.Project.$Project.$Stage = $projectStageKV
        ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFile
        Write-Verbose "Updated $ConfigFile"

        $projectStageHash = @{
            ConfigFile         = $ConfigFile
            ISBootstrapVersion = $ISBootstrapVersion
            Project            = $Project
            Stage              = $Stage

        }

        Set-ISHDeploymentConfiguration @projectStageHash
        Set-ISHDeploymentComponentConfiguration @projectStageHash
        Set-ISHDeploymentConfigurationLocation -Path $ConfigFile
    }

    end {

    }
}