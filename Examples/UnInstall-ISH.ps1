if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
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
    $inputParameterFiles=Get-ChildItem $rootPath -Filter "inputparameters-*.xml"

    $inputParameterFiles | ForEach-Object {
        $fileName=$_.Name
        if ($fileName -match "inputparameters-(?<suffix>.*)\.xml")
        {
            $suffix=$Matches["suffix"]
            Write-Debug "Uninstalling from $cdPath the $suffix"
            Uninstall-ISHDeployment -CDPath $cdPath -Suffix $suffix
            Write-Verbose "Uninstalled from $cdPath the $suffix"
        }
        else
        {
            Write-Warning "Not a valid input parameter file $fileName"
        }
    }
}

try
{

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }
    Invoke-CommandWrap -ComputerName $computerName -ScriptBlock $uninstallBlock -BlockName "Uninstall ISH" -UseParameters @("ishVersion")

}
finally
{
}
