$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\New-PSCredential.ps1"
. "$here\New-SqlServerQuerySplat.ps1"

$server = 'Server' + (Get-random)
$database = 'Database' + (Get-random)
$username = 'Username' + (Get-random)
$password = 'Password' + (Get-random)

Describe "Set-ISHDatabaseCrawlerRegistration" {
    Mock "Invoke-ISHMaintenance" {

    }
    Mock "New-SqlServerQuerySplat" {
        @{
            Server     = $server
            Database   = $database
            Credential = New-PSCredential -Username $username -Password $password
        }
    }
    It "Set-ISHDatabaseCrawlerRegistration - More than 2 registrations and 0 valid" {
        Mock "Invoke-SqlServerQuery" {
            if ($Sql -like "*WHERE*") {
                0
            }
            else {
                2
            }
        }
        Set-ISHDatabaseCrawlerRegistration
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 1 -ParameterFilter {
            $Crawler -and $UnRegisterAll
        }
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 1 -ParameterFilter {
            $Crawler -and $Register
        }
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 2
    }
    It "Set-ISHDatabaseCrawlerRegistration - More than 2 registrations and 1 valid" {
        Mock "Invoke-SqlServerQuery" {
            if ($Sql -like "*WHERE*") {
                1
            }
            else {
                2
            }
        }
        Set-ISHDatabaseCrawlerRegistration
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 1 -ParameterFilter {
            $Crawler -and $UnRegisterAll
        }
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 1 -ParameterFilter {
            $Crawler -and $Register
        }
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 2
    }
    It "Set-ISHDatabaseCrawlerRegistration - Exactly 1 registration and 0 valid" {
        Mock "Invoke-SqlServerQuery" {
            if ($Sql -like "*WHERE*") {
                0
            }
            else {
                1
            }
        }
        Set-ISHDatabaseCrawlerRegistration
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 1 -ParameterFilter {
            $Crawler -and $UnRegisterAll
        }
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 1 -ParameterFilter {
            $Crawler -and $Register
        }
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 2
    }
    It "Set-ISHDatabaseCrawlerRegistration - Exactly 1 registration and 1 valid" {
        Mock "Invoke-SqlServerQuery" {
            if ($Sql -like "*WHERE*") {
                1
            }
            else {
                1
            }
        }
        Set-ISHDatabaseCrawlerRegistration
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 0
    }
    It "Set-ISHDatabaseCrawlerRegistration - Exactly 0 registration" {
        Mock "Invoke-SqlServerQuery" {
            if ($Sql -like "*WHERE*") {
                0
            }
            else {
                0
            }
        }
        Set-ISHDatabaseCrawlerRegistration
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 1 -ParameterFilter {
            $Crawler -and $Register
        }
        Assert-MockCalled -CommandName "Invoke-ISHMaintenance" -Scope It -Exactly 1
    }
}


