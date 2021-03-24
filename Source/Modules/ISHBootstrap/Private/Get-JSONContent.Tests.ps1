$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. $here\Get-StageFolderPath.ps1
. $here\Get-JSONContentPath.ps1
. $here\Set-JSONContent.ps1
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

function random([string]$name) {
    $random = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object { [char]$_ })
    $name + "-" + $random
}

$Type = 'Test' + (Get-random)

Describe "Get-JSONContent" {
    $stageModulePath = "$($env:ProgramData)\ISHBootstrap.Pester"
    Remove-Item -Path $stageModulePath -Force -Recurse -ErrorAction SilentlyContinue
    It "Doesn't throw" {
        { Get-JSONContent -Type $Type } | Should Not Throw
    }
    It "Test file path" {
        $expectedPath = Join-Path -Path $stageModulePath -ChildPath "$Type.json"
        Test-Path -Path $expectedPath | Should BeExactly $false
    }
    It "Isn't null or empty but exactly {}" {
        (Get-JSONContent -Type $Type | ConvertTo-Json -Compress) | Should BeExactly "{}"
    }
}
