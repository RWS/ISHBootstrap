$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\Get-StageFolderPath.ps1"
. "$here\Get-JSONContentPath.ps1"

$Type = 'Test' + (Get-random)

Describe "Test-JSONContent" {
    $stageModulePath = "$($env:ProgramData)\ISHBootstrap.Pester"
    Remove-Item -Path $stageModulePath -Force -Recurse -ErrorAction SilentlyContinue
    It "Doesn't throw" {
        { Test-JSONContent -Type $Type } | Should Not Throw
    }
    It "Test-JSONContent -Type $Type" {
        Test-JSONContent -Type $Type | Should BeExactly $false
    }
}


