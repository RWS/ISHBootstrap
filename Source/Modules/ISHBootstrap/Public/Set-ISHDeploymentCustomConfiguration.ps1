<#
.Synopsis
   Configure Deployment configuration (project/stage) custom values
.DESCRIPTION
   Configure Deployment configuration (project/stage) custom values
#>
Function Set-ISHDeploymentCustomConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Single Key/Value")]
        [Parameter(Mandatory = $true, ParameterSetName = "File Key/Blob")]
        [ValidateScript( { Test-Path $_ })]
        [string]$ConfigFile,
        [Parameter(Mandatory = $true, ParameterSetName = "Single Key/Value")]
        [Parameter(Mandatory = $true, ParameterSetName = "File Key/Blob")]
        [string]$ISBootstrapVersion,
        [Parameter(Mandatory = $true, ParameterSetName = "Single Key/Value")]
        [Parameter(Mandatory = $true, ParameterSetName = "File Key/Blob")]
        [string]$Project,
        [Parameter(Mandatory = $true, ParameterSetName = "Single Key/Value")]
        [Parameter(Mandatory = $true, ParameterSetName = "File Key/Blob")]
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
        [string]$FilePath
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

        if ($PSCmdlet.ParameterSetName -eq 'File Key/Blob') {
            $Text = Get-Content -Raw -Path $FilePath
            $Bytes = [System.Text.Encoding]::Unicode.GetBytes($Text)
            $Value = [Convert]::ToBase64String($Bytes)
        }
        if (-not $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH.Custom) {
            $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH | Add-Member -MemberType NoteProperty -Name Custom -Value ([pscustomobject]@{$Key = $Value })
        }
        elseif ($keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH.Custom.$Key) {
            $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH.Custom.$Key = $Value
        }
        else {
            $keyValues.$ISBootstrapVersion.Project.$Project.$Stage.ISH.Custom | Add-Member -MemberType NoteProperty -Name $Key -Value ([string]$Value)
        }

        ConvertTo-Json $keyValues -Depth 30 | Format-Json | Out-File -FilePath $ConfigFile
        Write-Verbose "Updated $ConfigFile"
    }

    end {

    }
}