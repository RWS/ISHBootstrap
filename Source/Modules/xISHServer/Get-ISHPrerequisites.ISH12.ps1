. $PSScriptRoot\Get-ISHServerFolderPath.ps1
. $PSScriptRoot\Get-ISHOSInfo.ps1

function Get-ISHPrerequisites
{
    param(
        [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
        [string]$FTPHost,
        [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
        [pscredential]$Credential,
        [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
        [string]$FTPFolder,
        [Parameter(Mandatory=$true,ParameterSetName="No Download")]
        [switch]$FileNames
    )
    #
    $filesToDownload=@(
        #Common for 12 and 13
        "MSXML.40SP3.msi"
        "jdk-8u60-windows-x64.exe"
        "jre-8u60-windows-x64.exe"
        "javahelp-2_0_05.zip"
        "htmlhelp.zip"
        "V6-2-M9-Windows_X64_64E.exe"
        "V6-2-M9-Windows_X64_64E.exe.iss"
        "V6-2-M9-Windows_X64_64E.exe.vcredist_x64.exe"
        "V6-2-M9-Windows_X64_64E.exe.vcredist_x86.exe"
        "ODTwithODAC121012.zip"
        "ODTwithODAC121012.rsp"

        #Specific for 12
        "NETFramework2013_4.5_MicrosoftVisualC++Redistributable_(vcredist_x64).exe"
    )
    $osInfo=Get-ISHOSInfo
    if($osInfo.IsCore)
    {
        $filesToDownload+="vbrun60sp6.exe"
    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'From FTP' {
            Import-Module PSFTP -ErrorAction Stop
            $localPath=Get-ISHServerFolderPath
            Set-FTPConnection -Server $FTPHost -Credentials $Credential -UseBinary -KeepAlive -UsePassive | Out-Null
            $filesToDownload | ForEach-Object {
                $ftpUrl="$FTPFolder$_"

                Write-Debug "ftpUrl=$ftpUrl"
                Get-FTPItem -Path $ftpUrl -LocalPath $localPath -Overwrite | Out-Null
                Write-Verbose "Downloaded $ftpUrl"
            }
            break        
        }
        'No Download' {
            if($FileNames)
            {
                $filesToDownload
            }
            break
        }
    }
}