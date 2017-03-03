param(
    [Parameter(Mandatory=$true,ParameterSetName="From AWS S3")]
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [ValidateSet("12.0.3","12.0.4","13.0.0")]
    [string]$ISHVersion,
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [Parameter(Mandatory=$false,ParameterSetName="From FTP")]
    [switch]$DebugISHServer=$false,
    [Parameter(Mandatory=$true,ParameterSetName="From AWS S3")]
    [switch]$AWS,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [switch]$FTP
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

$ishServerVersion=($ISHVersion -split "\.")[0]

$dependencies=@{
    PowerShellGetModules=@(
        # https://www.powershellgallery.com/packages/ISHDeploy/
        @{
            Name="ISHDeploy.$ISHVersion"
            RequiredVersion="1.2"
        }
        # https://www.powershellgallery.com/packages/CertificatePS/
        @{
            Name="CertificatePS"
            RequiredVersion="1.3"
        }
    )
    GitHub=@(
    )
}

if(-not $DebugISHServer)
{
    $dependencies.PowerShellGetModules+=@{
        # https://www.powershellgallery.com/packages/ISHServer/
        Name="ISHServer.$ishServerVersion"
        RequiredVersion="1.3"
    }
}

switch($PSCmdlet.ParameterSetName) {
    'From AWS S3' {
        # https://www.powershellgallery.com/packages/AWSPowerShell/
        $dependencies.PowerShellGetModules+=@{
            Name="AWSPowerShell"
            RequiredVersion="3.3.46.0"
        }
        break
    }
    'From FTP' {
        # https://www.powershellgallery.com/packages/PSFTP/
        $dependencies.PowerShellGetModules+=@{
            Name="PSFTP"
            RequiredVersion="1.7"
        }
        break
    }
}
$dependencies

Write-Separator -Invocation $MyInvocation -Footer