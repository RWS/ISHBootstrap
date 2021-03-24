$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\Get-StageFolderPath.ps1"

function random([string]$name) {
    $random = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object { [char]$_ })
    $name + "-" + $random
}

$Type = 'Test' + (Get-random)

Describe "Get-JSONContentPath" {
    $stageModulePath = "$($env:ProgramData)\ISHBootstrap.Pester"
    Remove-Item -Path $stageModulePath -Force -Recurse -ErrorAction SilentlyContinue
    It "Doesn't throw" {
        { Get-JSONContentPath -Type $Type } | Should Not Throw
    }
    It "Get-JSONContentPath -Type $Type" {
        $expectedPath = Join-Path -Path $stageModulePath -ChildPath "$Type.json"
        Get-JSONContentPath -Type $Type | Should BeExactly $expectedPath
    }
}


