$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\..\Public\Set-Marker.ps1"
. "$here\..\Public\Test-Requirement.ps1"

Describe "Invoke-ISHCrawlerReIndex" {
    Mock "Invoke-ISHMaintenance" {

    }
    Mock "Set-Marker" {
    }
    It "Invoke-ISHCrawlerReIndex - First time" {
        Mock "Test-Requirement" {
            if($Marker -and ($Name -eq "ISH.EC2InvokedCrawlerReindex"))
            {
                $false
            }
            else
            {
                throw "Mock parameter $Name not expected"
            }
        }
        Invoke-ISHCrawlerReIndex
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 1 -ParameterFilter {
            $Crawler -and $ReIndex
        }
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 1
        Assert-MockCalled -CommandName "Set-Marker" -Scope It -Exactly 1 -ParameterFilter {
            $Name -eq "ISH.EC2InvokedCrawlerReindex"
        }
        Assert-MockCalled -CommandName "Set-Marker" -Scope It -Exactly 1
    }
    It "Invoke-ISHCrawlerReIndex - Not first time" {
        Mock "Test-Requirement" {
            if($Marker -and ($Name -eq "ISH.EC2InvokedCrawlerReindex"))
            {
                $true
            }
            else
            {
                throw "Mock parameter $Name not expected"
            }
        }
        Invoke-ISHCrawlerReIndex
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 0
        Assert-MockCalled -CommandName "Set-Marker" -Scope It -Exactly 0
    }
}