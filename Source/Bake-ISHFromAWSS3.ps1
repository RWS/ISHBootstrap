#requires -runasadministrator

param(
    [Parameter(Mandatory=$true,ParameterSetName="Default")]
    [Parameter(Mandatory=$true,ParameterSetName="AWS Credential")]
    [ValidateSet("12.0.3","12.0.4","13.0.0")]
    [string]$ISHVersion,
    [Parameter(Mandatory=$false,ParameterSetName="Default")]
    [Parameter(Mandatory=$false,ParameterSetName="AWS Credential")]
    [string]$MockConnectionString=$null,
    [Parameter(Mandatory=$true,ParameterSetName="AWS Credential")]
    [string]$AccessKey,
    [Parameter(Mandatory=$true,ParameterSetName="AWS Credential")]
    [string]$SecretKey
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

switch($ISHVersion) {
    '12.0.3' {
        $hash=@{
            BucketName="sct-released"
            ISHServerFolder="InfoShare/12.0/PreRequisites"
            ISHCDFolder="InfoShare/12.0/"
            ISHCDFileName="20170125.CD.InfoShare.12.0.3725.3.Trisoft-DITA-OT.exe"
        }
    }
    '12.0.4' {
        $hash=@{
            BucketName="sct-released"
            ISHServerFolder="InfoShare/12.0/PreRequisites"
            ISHCDFolder="InfoShare/12.0/"
            ISHCDFileName="20170302.CD.InfoShare.12.0.3902.4.Prod.Trisoft-DITA-OT.exe"
        }
    }
    '13.0.0' {
        $hash=@{
            BucketName="sct-notreleased"
            ISHServerFolder="InfoShare/13.0/PreRequisites"
            ISHCDFolder="InfoShare/13.0/"
            ISHCDFileName="20170202.CD.InfoShare.13.0.2602.0.Test.Trisoft-DITA-OT.exe"
        }
    }
}

if($PSCmdlet.ParameterSetName -eq "AWS Credential")
{
    $hash.AccessKey=$AccessKey
    $hash.SecretKey=$SecretKey
}

$hash.ConnectionString=$MockConnectionString

& $buildersPath\Prerequisites\Install-Prerequisites.ps1 -NuGet
$prerequisites=& $buildersPath\Prerequisites\New-PrerequisitesList.ps1 -ISHVersion $ishVersion -AWS
& $buildersPath\Prerequisites\Install-Prerequisites.ps1 -Prerequisites $prerequisites

& $buildersPath\Initialize-ISHImage.ps1 @hash -ISHVersion $ishVersion

