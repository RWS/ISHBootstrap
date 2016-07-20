function Install-ISHDeployment{
    param (
        [Parameter(Mandatory=$true)]
        $CDPath,
        [Parameter(Mandatory=$true)]
        $InputParametersPath
    )
    $installToolPath=Join-Path $CDPath "__InstallTool\InstallTool.exe"
    $installPlanPath=Join-Path $CDPath "__InstallTool\installplan.xml"
    $installToolArgs=@("-Install",
        "-cdroot",$CDPath,
        "-installplan",$installPlanPath
        "-inputparameters",$InputParametersPath
        )
    & $installToolPath $installToolArgs
}