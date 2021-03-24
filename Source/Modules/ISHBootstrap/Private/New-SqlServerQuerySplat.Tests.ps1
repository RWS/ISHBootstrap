$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\New-PSCredential.ps1"

$server = 'Server' + (Get-random)
$database = 'Database' + (Get-random)
$username = 'Username' + (Get-random)
$password = 'Password' + (Get-random)

Describe "New-SqlServerQuerySplat" {
    Mock "Get-ISHIntegrationDB" {
        $mockConnectionStringFragments = @(
            "$('Name' + (Get-random))=$('Value' + (Get-random))"
            "Data Source=$server"
            "$('Name' + (Get-random))=$('Value' + (Get-random))"
            "Initial Catalog=$database"
            "$('Name' + (Get-random))=$('Value' + (Get-random))"
            "User ID=$username"
            "$('Name' + (Get-random))=$('Value' + (Get-random))"
            "Password=$Password"
            "$('Name' + (Get-random))=$('Value' + (Get-random))"
        )
        [pscustomobject]@{
            RawConnectionString = ($mockConnectionStringFragments | Sort-Object { Get-Random }) -join ';'
        }
    }
    It "New-SqlServerQuerySplat" {
        $splat = New-SqlServerQuerySplat
        $splat.Server | Should BeExactly $server
        $splat.Database | Should BeExactly $database
        $splat.Credential.Username | Should BeExactly $username
    }
}


