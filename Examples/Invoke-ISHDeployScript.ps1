param(
    [Parameter(Mandatory=$false)]
    [switch]$UseISHDeployImplicit=$false
)
if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"


try
{

    . "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
    $computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName"

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }

    . "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

    $ishDeployments=Get-ISHBootstrapperContextValue -ValuePath "ISHDeployment"
    $ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"

    foreach($ishDeployment in $ishDeployments)
    {
        $deploymentName="InfoShare$($ishDeployment.Suffix)"
        $ishDeployment.Scripts | ForEach-Object {
            $scriptFileName=$_
            $folderPath=Get-ISHBootstrapperContextValue -ValuePath "FolderPath"
            $scriptPath=Join-Path $folderPath $scriptFileName
            Write-Debug "scriptFileName=$scriptFileName"
            Write-Debug "folderPath=$folderPath"

            if($UseISHDeployImplicit)
            {
                $scriptPath=$scriptPath.Replace(".ps1",".ImplicitRemoting.ps1")
            }
            Write-Debug "scriptPath=$scriptPath"
            $scriptPath=Resolve-Path $scriptPath

            if($UseISHDeployImplicit)
            {
                & $scriptPath -Computer $computerName -DeploymentName $deploymentName -ISHVersion $ishVersion
            }
            else
            {
                & $scriptPath -Computer $computerName -DeploymentName $deploymentName
            }
            Write-Verbose "Executing $scriptPath -Computer $computerName -DeploymentName $deploymentName"
        }
    }

}
finally
{
}
