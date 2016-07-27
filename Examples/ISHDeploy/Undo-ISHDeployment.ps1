if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

try
{
    $sourcePath=Resolve-Path "$PSScriptRoot\..\..\Source"
    $cmdletsPaths="$sourcePath\Cmdlets"
    $scriptsPaths="$sourcePath\Scripts"

    . "$PSScriptRoot\..\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
    . "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

    $computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName"

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }
    
    $undoBlock={
        $deployment = Get-ISHDeployment -Name $deploymentName
        Undo-ISHDeployment -ISHDeployment $deployment
        Clear-ISHDeploymentHistory -ISHDeployment $deployment
    }
    $ishDeployments=Get-ISHBootstrapperContextValue -ValuePath "ISHDeployment"
    foreach($ishDeployment in $ishDeployments)
    {
        $deploymentName="InfoShare$($ishDeployment.Suffix)"
        Invoke-CommandWrap -ComputerName $computerName -ScriptBlock $undoBlock -BlockName "Undo deployment $deploymentName" -UseParameters @("deploymentName")
    }
}
finally
{
}
