#reguires -runasadministrator

param(
    [Parameter(Mandatory=$true,ParameterSetName="From AWS S3")]
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [ValidateSet("12.0.3","12.0.4","13.0.0")]
    [string]$ISHVersion,
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [Parameter(Mandatory=$false,ParameterSetName="From FTP")]
    [switch]$DebugISHServer=$false,
    [Parameter(Mandatory=$false,ParameterSetName="From AWS S3")]
    [switch]$AWS,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [switch]$FTP
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

$ishServerVersion=($ISHVersion -split "\.")[0]


#region Update NuGet Package provider
$blockName="Installing NuGet PackageProvider" 
Write-Progress @scriptProgress -Status $blockName
Write-Host $blockName

Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
#endregion

#region Installing modules
$moduleNames=@(
    "ISHDeploy.$ISHVersion"
    "CertificatePS"
)
if(-not $DebugISHServer)
{
    $moduleNames+="ISHServer.$ishServerVersion"
}

switch($PSCmdlet.ParameterSetName) {
    'From AWS S3' {
        $moduleNames+="AWSPowerShell"
    }
    'From FTP' {
        $moduleNames+="PSFTP"
    }
}

foreach($name in $moduleNames)
{
    $blockName="Installing powershell module $name"
    Write-Progress @scriptProgress -Status $blockName
    Write-Host $blockName

    Install-Module $name -Force
}

#endregion


Write-Separator -Invocation $MyInvocation -Footer