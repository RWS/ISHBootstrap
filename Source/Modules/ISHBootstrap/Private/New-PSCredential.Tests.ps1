$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "New-PSCredential" {
    It "New-PSCredential" {
        $username = 'Username' + (Get-random)
        $password = 'Password' + (Get-random)

        $credential = New-PSCredential -Username $username -Password $password
        $credential.Username | Should BeExactly $username
        $credential.GetNetworkCredential().Password | Should BeExactly $password
    }
}


