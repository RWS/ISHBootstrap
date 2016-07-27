if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

try
{
    $sourcePath=Resolve-Path "$PSScriptRoot\..\..\Source"
    $cmdletsPaths="$sourcePath\Cmdlets"
    $scriptsPaths="$sourcePath\Scripts"

    . "$PSScriptRoot\..\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
    . "$cmdletsPaths\Helpers\Invoke-ImplicitRemoting.ps1"

    $computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName"

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }
    
    $ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
    $ishDelpoyModuleName="ISHDeploy.$ishVersion"

    $ishDeployments=Get-ISHBootstrapperContextValue -ValuePath "ISHDeployment"
    $undoBlock={
        foreach($ishDeployment in $ishDeployments)
        {
            $deploymentName="InfoShare$($ishDeployment.Suffix)"
            Undo-ISHDeployment -ISHDeployment $deploymentName
            Clear-ISHDeploymentHistory -ISHDeployment $deploymentName
        }
    }

    Invoke-ImplicitRemoting -ScriptBlock $undoBlock -BlockName "Undo deployment" -ComputerName $computerName -ImportModule $ishDelpoyModuleName
}
finally
{
}
