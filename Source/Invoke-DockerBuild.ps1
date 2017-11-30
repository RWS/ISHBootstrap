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
            $imageName="ish"
            $dockerFileName="ISH.dockerfile"
        }
    'MSSQLExpress' {
            $imageName="ishmssql"
            $dockerFileName="ISH.MSSQL.dockerfile"
        }
}

$dockerArgs+=@(
    "-t"
    "asarafian/$($imageName):$ISHVersion"
    "-f"
    "$dockerFileName"
    "--build-arg"
    "ishVersion=$ISHVersion"
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

$caption=(Get-CimInstance Win32_OperatingSystem).Caption
$regex="Microsoft Windows (?<Server>(Server) )?((?<Version>[0-9]+( R[0-9]?)?) )?(?<Type>.+)"
if($caption -match $regex)
{
    $isWindowsClient=$Matches["Server"] -eq $null
}
else
{
    throw "Could not determine if the operating system is client of not"
}

if($isWindowsClient)
{
    $memory="4GB"
    Write-Warning "Client operating system detected. Container will run with Hyper-V isolation. Increasing the memory size to $memory"
    $dockerArgs+=@(
        "-m"
        $memory
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