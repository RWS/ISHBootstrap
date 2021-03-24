$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

$webPath = 'WebPath' + (Get-random)
$appPath = 'AppPath' + (Get-random)

Describe "Get-ISHDeploymentPath" {
    Mock "Get-ISHDeployment" {
        [pscustomobject]@{
            WebPath = $webPath
            AppPath = $appPath
        }
    }

    It "Get-ISHDeploymentPath -EnterViaUI" {
        $actual = Get-ISHDeploymentPath -EnterViaUI
        $actual.AbsolutePath | Should Be "$webPath\Author\EnterViaUI"
        $actual.RelativePath | Should Be "Author\EnterViaUI"
    }
    It "Get-ISHDeploymentPath -JettyIPAccess" {
        $actual = Get-ISHDeploymentPath -JettyIPAccess
        $actual.AbsolutePath | Should Be "$appPath\Utilities\SolrLucene\Jetty\etc\jetty-ipaccess.xml"
        $actual.RelativePath | Should Be "Utilities\SolrLucene\Jetty\etc\jetty-ipaccess.xml"
    }
}
