param(
    
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

$dbName="InfoShare"
"Provider=SQLOLEDB.1;Integrated Security=SSPI;Persist Security Info=False;Initial Catalog=$dbName;Data Source=.\SQLEXPRESS"

Write-Separator -Invocation $MyInvocation -Footer