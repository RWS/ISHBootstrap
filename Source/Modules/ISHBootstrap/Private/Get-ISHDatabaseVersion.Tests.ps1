$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\New-PSCredential.ps1"
. "$here\New-SqlServerQuerySplat.ps1"

$server = 'Server' + (Get-random)
$database = 'Database' + (Get-random)
$username = 'Username' + (Get-random)
$password = 'Password' + (Get-random)

$version = 'Version' + (Get-random)

Describe "Get-ISHDatabaseVersion" {
    Mock "Invoke-SqlServerQuery" {
        $version
    }
    Mock "New-SqlServerQuerySplat" {
        @{
            Server     = $server
            Database   = $database
            Credential = New-PSCredential -Username $username -Password $password
        }
    }
    It "Get-ISHDatabaseVersion" {
        $actualVersion = Get-ISHDatabaseVersion
        $actualVersion | Should BeExactly $version
        Assert-MockCalled -CommandName "Invoke-SqlServerQuery" -Scope It -Exactly 1 -ParameterFilter {
            $sql -and $NoTrans -and $Scalar -and $Server -and $Database -and $Credential
        }
    }
}


