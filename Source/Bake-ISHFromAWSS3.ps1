#requires -runasadministrator

param(
    [Parameter(Mandatory=$true,ParameterSetName="Default Authorization")]
    [Parameter(Mandatory=$true,ParameterSetName="Custom Authorization")]
    [ValidateSet("12.0.3","12.0.4","13.0.0","13.0.1","13.0.2","14.0.0","14.0.1","14.0.2","14.0.3","14.0.4","15.0.0","15.1")]
    [string]$ISHVersion,
    [Parameter(Mandatory=$false,ParameterSetName="Default Authorization")]
    [Parameter(Mandatory=$false,ParameterSetName="Custom Authorization")]
    [string]$MockConnectionString=$null,
    [Parameter(Mandatory=$true,ParameterSetName="Default Authorization")]
    [Parameter(Mandatory=$true,ParameterSetName="Custom Authorization")]
    [string]$BucketName,
    [Parameter(Mandatory=$true,ParameterSetName="Default Authorization")]
    [Parameter(Mandatory=$true,ParameterSetName="Custom Authorization")]
    [string]$ISHServerFolder,
    [Parameter(Mandatory=$true,ParameterSetName="Default Authorization")]
    [Parameter(Mandatory=$true,ParameterSetName="Custom Authorization")]
    [string]$ISHCDFolder,
    [Parameter(Mandatory=$true,ParameterSetName="Default Authorization")]
    [Parameter(Mandatory=$true,ParameterSetName="Custom Authorization")]
    [string]$ISHCDFileName,
    [Parameter(Mandatory=$true,ParameterSetName="Custom Authorization")]
    [string]$AccessKey,
    [Parameter(Mandatory=$true,ParameterSetName="Custom Authorization")]
    [string]$SecretKey,
    [Parameter(Mandatory=$false,ParameterSetName="Default Authorization")]
    [Parameter(Mandatory=$false,ParameterSetName="Custom Authorization")]
    [bool]$InstallISHPrerequisites=$true,
    [Parameter(Mandatory=$false,ParameterSetName="Default Authorization")]
    [Parameter(Mandatory=$false,ParameterSetName="Custom Authorization")]
    [bool]$InstallISHApplicationServer=$true,
    [Parameter(Mandatory=$false,ParameterSetName="Default Authorization")]
    [Parameter(Mandatory=$false,ParameterSetName="Custom Authorization")]
    [string]$MockAMConnectionString=$null,
    [Parameter(Mandatory=$false,ParameterSetName="Default Authorization")]
    [Parameter(Mandatory=$false,ParameterSetName="Custom Authorization")]
    [string]$MockBFFConnectionString=$null,
    [Parameter(Mandatory=$false,ParameterSetName="Default Authorization")]
    [Parameter(Mandatory=$false,ParameterSetName="Custom Authorization")]
    [string]$MockIDConnectionString=$null,
    [Parameter(Mandatory=$false,ParameterSetName="Default Authorization")]
    [Parameter(Mandatory=$false,ParameterSetName="Custom Authorization")]
    [string]$MockMetricsConnectionString=$null
)

if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}
# Normalize to null incase the packer and container feed the parameter with empty
if($MockConnectionString -eq "")
{
    $MockConnectionString=""
}

$buildersPath=Join-Path $PSScriptRoot Builders

$hash=@{
    BucketName=$BucketName
    ISHServerFolder=$ISHServerFolder
    ISHCDFolder=$ISHCDFolder
    ISHCDFileName=$ISHCDFileName
    InstallISHPrerequisites=$InstallISHPrerequisites
    InstallISHApplicationServer=$InstallISHApplicationServer
}

if($PSCmdlet.ParameterSetName -eq "Custom Authorization")
{
    $hash.AccessKey=$AccessKey
    $hash.SecretKey=$SecretKey
}

$hash.ConnectionString=$MockConnectionString
$hash.AMConnectionString=$MockAMConnectionString
$hash.BFFConnectionString=$MockBFFConnectionString
$hash.IDConnectionString=$MockIDConnectionString
$hash.MetricsConnectionString=$MockMetricsConnectionString
& $buildersPath\Initialize-ISHImage.ps1 @hash -ISHVersion $ishVersion
