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

$ftpHost=Get-ISHBootstrapperContextValue -ValuePath "FTP.Host"
$ftpIp=Get-ISHBootstrapperContextValue -ValuePath "FTP.Ip"
$ftpUser=Get-ISHBootstrapperContextValue -ValuePath "FTP.User"
$ftpPassword=Get-ISHBootstrapperContextValue -ValuePath "FTP.Password"
$ftpCDFolder=Get-ISHBootstrapperContextValue -ValuePath "FTP.ISHCDFolder"
$ftpCDFileName=Get-ISHBootstrapperContextValue -ValuePath "FTP.ISHCDFileName"

$copyBlock= {
    $targetPath="C:\IshCD\$ishVersion"
    Write-Debug "targetPath=$targetPath"
    Import-Module PSFTP -ErrorAction Stop

    if(-not (Test-Connection $ftpHost -Quiet))
    {
        Write-Warning "Using $ftpIp instead of $ftpHost"
        $ftpHost=$ftpIp
    }

    $sdlCredentials=New-Credential -UserName $ftpUser -Password $ftpPassword
    Set-FTPConnection -Server $ftpHost -Credentials $sdlCredentials -UseBinary -KeepAlive -UsePassive | Out-Null
    $ftpUrl="$ftpCDFolder$ftpCDFileName"
    $localPath=$env:TEMP

    Write-Debug "ftpUrl=$ftpUrl"
    Get-FTPItem -Path $ftpUrl -LocalPath $localPath -Overwrite | Out-Null
    Write-Verbose "Downloaded $ftpUrl"

    $cdPath=Join-Path $env:TEMP $ftpCDFileName
    Write-Debug "cdPath=$cdPath"

    Write-Debug "targetPath=$targetPath"
    if(-not (Test-Path $targetPath))
    {
        New-Item $targetPath -ItemType Directory | Out-Null
    }
    Remove-Item "$targetPath\*" -Force -Recurse
    Write-Verbose "$targetPath is ready"
    
    $arguments=@("-d$targetPath","-s")
    Write-Debug "Unzipping $cdPath in $targetPath"
    Start-Process $cdPath -ArgumentList $arguments -Wait
    Write-Host "Unzipped $cdPath in $targetPath"
}

try
{

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }

    Invoke-CommandWrap -ComputerName $computerName -Credential $credential -ScriptBlock $copyBlock -BlockName "Copy and Extract ISH.$ishVersion" -UseParameters @("ishVersion","ftpHost","ftpIp","ftpUser","ftpPassword","ftpCDFolder","ftpCDFileName")
}
finally
{
}
