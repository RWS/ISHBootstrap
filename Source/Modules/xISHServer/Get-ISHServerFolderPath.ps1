function Get-ISHServerFolderPath
{
    param (
        [Parameter(Mandatory=$false)]
        [switch]$UNC=$false
    )
    $moduleName=$($MyInvocation.MyCommand.Module)
    $programDataPath=Join-Path $env:ProgramData $moduleName
    if(-not (Test-Path $programDataPath))
    {
        New-Item $programDataPath -ItemType Directory |Out-Null
    }
    if($UNC)
    {
        return "\\"+$env:COMPUTERNAME+"\"+$programDataPath.Replace($env:SystemDrive,$env:SystemDrive.Replace(":","$"))
    }
    else
    {
        return $programDataPath
    }
}