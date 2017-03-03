param(
    [Parameter(Mandatory=$true,ParameterSetName="WindowsServerCore")]
    [Parameter(Mandatory=$true,ParameterSetName="MSSQLExpress")]
    [string]$ISHVersion,
    [Parameter(Mandatory=$true,ParameterSetName="WindowsServerCore")]
    [string]$MockConnectionString,
    [Parameter(Mandatory=$true,ParameterSetName="WindowsServerCore")]
    [Parameter(Mandatory=$true,ParameterSetName="MSSQLExpress")]
    [string]$AccessKey,
    [Parameter(Mandatory=$true,ParameterSetName="WindowsServerCore")]
    [Parameter(Mandatory=$true,ParameterSetName="MSSQLExpress")]
    [string]$SecretKey
)

if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$cmdletsPaths="$PSScriptRoot\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

$dockerArgs=@(
    "build"
)

switch ($PSCmdlet.ParameterSetName) {
    'WindowsServerCore' {
            $tagPrefix="ish"
            $dockerFileName="ISH.dockerfile"
        }
    'MSSQLExpress' {
            $tagPrefix="ishmssql"
            $dockerFileName="ISH.MSSQL.dockerfile"
        }
}

$dockerArgs+=@(
    "-t"
    "sarafian/$($tagPrefix):$ISHVersion"
    "-f"
    "$dockerFileName"
    "--build-arg"
    "accessKey=$AccessKey"
    "--build-arg"
    "secretKey=$SecretKey"
)

if($PSCmdlet.ParameterSetName -eq "WindowsServerCore")
{
    $dockerArgs+=@(
        "--build-arg"
        "mockConnectionString=$MockConnectionString"
    )
}

$dockerArgs+=@(
    "."
)

Push-Location -Path $PSScriptRoot -StackName Docker

try
{
    Write-Host "docker $dockerArgs"
    & docker $dockerArgs 2>&1
    Write-Host "LASTEXITCODE=$LASTEXITCODE"
}
finally
{
    Pop-Location -StackName Docker
}
Write-Separator -Invocation $MyInvocation -Footer