$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\..\Public\Get-UriStatus.ps1"

$randomUri = 'Uri' + (Get-random)
$maxIterations = 5

Describe "Wait-UriStatus" {
    BeforeEach {
        Set-Variable -Name "Iteration" -Value 1 -Scope Global
    }
    AfterEach {
        Remove-Variable -Name "Iteration" -Scope Global -ErrorAction SilentlyContinue
    }
    Mock "Get-UriStatus" {
        $iteration = Get-Variable -Name "Iteration" -Scope Global -ValueOnly
        Write-Debug "iteration=$iteration"
        if ($iteration -lt $maxIterations) {
            Set-Variable -Name "Iteration" -Value ($iteration + 1) -Scope Global
            0
        }
        else {
            200
        }
    }

    It "Wait-UriStatus -Seconds" {
        $measure = Measure-Command -Expression { Wait-UriStatus -Uri $randomUri -Status 200 -Seconds 1 }
        $iteration | Should BeExactly 5
        Assert-MockCalled -CommandName "Get-UriStatus" -Scope It -Exactly $maxIterations -ParameterFilter {
            $Uri -eq $randomUri
        }
    }
    It "Wait-UriStatus -Milliseconds" {
        $measure = Measure-Command -Expression { Wait-UriStatus -Uri $randomUri -Status 200 -Milliseconds 10 }
        $iteration | Should BeExactly 5
        Assert-MockCalled -CommandName "Get-UriStatus" -Scope It -Exactly $maxIterations -ParameterFilter {
            $Uri -eq $randomUri
        }
    }
}