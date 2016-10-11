if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
$credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke
$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$uninstallBlock= {
    $rootPath="C:\ISHCD\$ishVersion"
    Write-Debug "rootPath=$rootPath"

    $cdPath=(Get-ChildItem $rootPath |Where-Object{Test-Path $_.FullName -PathType Container}| Sort-Object FullName -Descending)|Select-Object -ExpandProperty FullName -First 1
    Write-Debug "cdPath=$cdPath"
    if(-not $cdPath)
    {
        Write-Warning "C:\ISHCD\$ishVersion does not contain a cd."
        return
    }

    $ishDeployModuleName="ISHDeploy.$ishVersion"
    if(Get-Module $ishDeployModuleName -ListAvailable)
    {
        Get-ISHDeployment |Select-Object -ExpandProperty Name | ForEach-Object {
            Write-Debug "Uninstalling from $cdPath the deployment $_"
            Uninstall-ISHDeployment -CDPath $cdPath -Name $_
            Write-Verbose "Uninstalled from $cdPath the deployment $_"
        }
    }
    else
    {
        Write-Warning "$ishDeployModuleName is not available. Falling back into working with the files created by Install-ISH.ps1 ($rootPath\inputparameters-*.xml)"
        $inputParameterFiles=Get-ChildItem $rootPath -Filter "inputparameters-*.xml"

        $inputParameterFiles | ForEach-Object {
            $fileName=$_.Name
            if ($fileName -match "inputparameters-(?<name>.*)\.xml")
            {
                $name=$Matches["name"]
                Write-Debug "Uninstalling from $cdPath the deployment $name"
                Uninstall-ISHDeployment -CDPath $cdPath -Name $name
                Write-Verbose "Uninstalled from $cdPath the deployment $name"
            }
            else
            {
                Write-Warning "Not a valid input parameter file $fileName"
            }
        }
    }
}

try
{

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }
    Invoke-CommandWrap -ComputerName $computerName -Credential $credential -ScriptBlock $uninstallBlock -BlockName "Uninstall ISH" -UseParameters @("ishVersion")

}
finally
{
}
