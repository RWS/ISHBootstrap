function Uninstall-ISHDeployment{
    param (
        [Parameter(Mandatory=$true)]
        $CDPath,
        [Parameter(Mandatory=$false)]
        $Name="InfoShare"
    )
    $installToolPath=Join-Path $CDPath "__InstallTool\InstallTool.exe"
    $installToolArgs=@("-Uninstall",
        "-project",$Name
        )
    & $installToolPath $installToolArgs
}