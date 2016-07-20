function Uninstall-ISHDeployment{
    param (
        [Parameter(Mandatory=$true)]
        $CDPath,
        [Parameter(Mandatory=$true)]
        $Suffix
    )
    $project="InfoShare$Suffix"
    $installToolPath=Join-Path $CDPath "__InstallTool\InstallTool.exe"
    $installToolArgs=@("-Uninstall",
        "-project",$project
        )
    & $installToolPath $installToolArgs
}