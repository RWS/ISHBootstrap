param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [string]$DeploymentName
)        
$ishBootStrapRootPath=Resolve-Path "$PSScriptRoot\..\.."
$cmdletsPaths="$ishBootStrapRootPath\Source\Cmdlets"
$scriptsPaths="$ishBootStrapRootPath\Source\Scripts"

. $ishBootStrapRootPath\Examples\ISHDeploy\Cmdlets\Write-Separator.ps1
Write-Separator -Invocation $MyInvocation -Header -Name "Configure"

if(-not $Computer)
{
    & "$scriptsPaths\Helpers\Test-Administrator.ps1"
}

if(-not (Get-Command Invoke-CommandWrap -ErrorAction SilentlyContinue))
{
    . $cmdletsPaths\Helpers\Invoke-CommandWrap.ps1
}  


$setBlock= {
    Set-ISHSTSRelyingParty -ISHDeployment $DeploymentName -Name "3rd party" -Realm "https://3rdparty.example.com/"
    Set-ISHSTSRelyingParty -ISHDeployment $DeploymentName -Name "Content Review" -Realm "https://lc.example.com/" -LC
    Set-ISHSTSRelyingParty -ISHDeployment $DeploymentName -Name "Quality Assistant" -Realm "https://bl.example.com/" -BL
}


try
{
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $setBlock -BlockName "Add relying parties on $DeploymentName" -UseParameters @("DeploymentName")
}
finally
{

}

Write-Separator -Invocation $MyInvocation -Footer -Name "Configure"