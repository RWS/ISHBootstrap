$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\Get-ISHFullTextIndexExternalDependency.ps1"
. "$here\..\Public\Get-Tag.ps1"

$project = 'Project' + (Get-random)
$stage = 'Stage' + (Get-random)
$accessHostName = 'AccessHostName' + (Get-random)

Describe "Get-ISHServiceFullTextIndexUri" {
    Mock "Get-ISHDeployment" {
        [PSCustomObject]@{
            AccessHostName = $accessHostName
        }
    }
    Mock "Get-Tag" {
        if ($Name -eq "Project") {
            $project
        }
        elseif ($Name -eq "Stage") {
            $stage
        }
        else {
            throw "Name $Name is not an expected mocked parameter value"
        }
    }
    It "Get-ISHServiceFullTextIndexUri - ExternalEC2" {
        Mock "Get-ISHFullTextIndexExternalDependency" {
            "ExternalEC2"
        }
        Get-ISHServiceFullTextIndexUri | Should BeExactly "http://backendsingle.ish.internal.$($project)-$($stage).$($accessHostName):8078/solr/"
        Assert-MockCalled -CommandName "Get-ISHDeployment" -Scope It -Exactly 1
        Assert-MockCalled -CommandName "Get-Tag" -Scope It -Exactly 1 -ParameterFilter {
            $Name -eq "Project"
        }
        Assert-MockCalled -CommandName "Get-Tag" -Scope It -Exactly 1 -ParameterFilter {
            $Name -eq "Stage"
        }
        Assert-MockCalled -CommandName "Get-ISHFullTextIndexExternalDependency" -Scope It -Exactly 1
    }
    It "Get-ISHServiceFullTextIndexUri - Local" {
        Mock "Get-ISHFullTextIndexExternalDependency" {
            "Local"
        }
        Get-ISHServiceFullTextIndexUri | Should BeExactly "http://127.0.0.1:8078/solr/"
        Assert-MockCalled -CommandName "Get-ISHDeployment" -Scope It -Exactly 0
        Assert-MockCalled -CommandName "Get-Tag" -Scope It -Exactly 0
        Assert-MockCalled -CommandName "Get-ISHFullTextIndexExternalDependency" -Scope It -Exactly 1
    }
    It "Get-ISHServiceFullTextIndexUri - None" {
        Mock "Get-ISHFullTextIndexExternalDependency" {
            "None"
        }
        Get-ISHServiceFullTextIndexUri | Should BeExactly "http://127.0.0.1:8078/solr/"
        Assert-MockCalled -CommandName "Get-ISHDeployment" -Scope It -Exactly 0
        Assert-MockCalled -CommandName "Get-Tag" -Scope It -Exactly 0
        Assert-MockCalled -CommandName "Get-ISHFullTextIndexExternalDependency" -Scope It -Exactly 1
    }
}

