$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\..\Private\Wait-UriStatus.ps1"

$webAppNameCM = 'WebAppNameCM' + (Get-random)
$webAppNameWS = 'WebAppNameWS' + (Get-random)
$webAppNameSTS = 'WebAppNameSTS' + (Get-random)

Describe "Wait-ISHWeb" {
    BeforeEach {
        Set-Variable -Name "Iteration" -Value 1 -Scope Global
    }
    AfterEach {
        Remove-Variable -Name "Iteration" -Scope Global -ErrorAction SilentlyContinue
    }
    Mock "Get-ISHDeployment" {
        [PSCustomObject]@{
            WebAppNameCM  = $webAppNameCM
            WebAppNameWS  = $webAppNameWS
            WebAppNameSTS = $webAppNameSTS
        }
    }
    Mock "Wait-UriStatus" {
    }

    It "Wait-ISHWeb" {
        Wait-ISHWeb
        Assert-MockCalled -CommandName "Get-ISHDeployment" -Scope It -Exactly 1
        Assert-MockCalled -CommandName "Wait-UriStatus" -Scope It -Exactly 1 -ParameterFilter {
            ($Uri -eq "https://localhost/") -and ($Status -eq 200)
        }
        Assert-MockCalled -CommandName "Wait-UriStatus" -Scope It -Exactly 1 -ParameterFilter {
            ($Uri -eq "https://localhost/$webAppNameCM/") -and ($Status -eq 302)
        }
        Assert-MockCalled -CommandName "Wait-UriStatus" -Scope It -Exactly 1 -ParameterFilter {
            ($Uri -eq "https://localhost/$webAppNameWS/ConnectionConfiguration.xml") -and ($Status -eq 200)
        }
        Assert-MockCalled -CommandName "Wait-UriStatus" -Scope It -Exactly 1 -ParameterFilter {
            ($Uri -eq "https://localhost/$webAppNameWS/Application25.asmx") -and ($Status -eq 200)
        }
        Assert-MockCalled -CommandName "Wait-UriStatus" -Scope It -Exactly 1 -ParameterFilter {
            ($Uri -eq "https://localhost/$webAppNameWS/Wcf/API25/Application.svc") -and ($Status -eq 200)
        }
        Assert-MockCalled -CommandName "Wait-UriStatus" -Scope It -Exactly 1 -ParameterFilter {
            ($Uri -eq "https://localhost/$webAppNameSTS/") -and ($Status -eq 200)
        }
        Assert-MockCalled -CommandName "Wait-UriStatus" -Scope It -Exactly 6
    }
}