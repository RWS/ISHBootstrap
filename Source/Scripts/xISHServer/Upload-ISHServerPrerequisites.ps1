param (
    [Parameter(Mandatory=$false)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$true)]
    [string]$PrerequisitesSourcePath,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion
)    
. $PSScriptRoot\..\..\Cmdlets\Helpers\Invoke-CommandWrap.ps1

if($Computer)
{
    . $PSScriptRoot\..\..\Cmdlets\Helpers\Add-ModuleFromRemote.ps1
    . $PSScriptRoot\..\..\Cmdlets\Helpers\Remove-ModuleFromRemote.ps1
}

try
{
    if($Computer)
    {
        $ishServerModuleName="xISHServer.$ISHServerVersion"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Name $ishServerModuleName
    }

    $filesToCopy=@(
        "MSXML.40SP3.msi"
        "jdk-8u60-windows-x64.exe"
        "jre-8u60-windows-x64.exe"
        "javahelp-2_0_05.zip"
        "htmlhelp.zip"
        "AHFormatter.lic"
        "V6-2-M9-Windows_X64_64E.exe"
        "V6-2-M9-Windows_X64_64E.exe.iss"
        "V6-2-M9-Windows_X64_64E.exe.vcredist_x64.exe"
        "V6-2-M9-Windows_X64_64E.exe.vcredist_x86.exe"
        "ODTwithODAC121012.zip"
        "ODTwithODAC121012.rsp"
    )

    switch ($ISHServerVersion)
    {
        '12' {
            $filesToCopy+="NETFramework2013_4.5_MicrosoftVisualC++Redistributable_(vcredist_x64).exe"
        }
        '13' {
            $filesToCopy+="NETFramework2015_4.6.1.xxxxx_(NDP461-KB3102436-x86-x64-AllOS-ENU).exe"
            $filesToCopy+="NETFramework2015_4.6_MicrosoftVisualC++Redistributable_(vc_redist.x64).exe"
        }
    }
    Write-Debug "filesToCopy=$filesToCopy"
    $filePathToCopy=$filesToCopy|ForEach-Object{Join-Path $PrerequisitesSourcePath $_}
    
    if($Computer)
    {
        $targetPath=Get-ISHServerFolderPath -UNC
    }    
    else
    {
        $targetPath=Get-ISHServerFolderPath
    }
    Write-Debug "targetPath=$targetPath"
    Copy-Item -Path $filePathToCopy -Destination $targetPath -Force

    Write-Verbose "Uploaded files to $targetPath"
}

finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
}

