param (
    [Parameter(Mandatory=$false)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [string]$PrerequisitesSourcePath,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion
)    
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

if($Computer)
{
    . $cmdletsPaths\Helpers\Add-ModuleFromRemote.ps1
    . $cmdletsPaths\Helpers\Remove-ModuleFromRemote.ps1
}

try
{
    if($Computer)
    {
        $ishServerModuleName="xISHServer.$ISHServerVersion"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Credential $Credential -Name $ishServerModuleName
    }
    
    $osInfo=Get-ISHOSInfo
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
            if($osInfo.Server -eq "2016")
            {
            }
            else
            {
                $filesToCopy+="NETFramework2015_4.6.1.xxxxx_(NDP461-KB3102436-x86-x64-AllOS-ENU).exe"
            }

            $filesToCopy+="NETFramework2015_4.6_MicrosoftVisualC++Redistributable_(vc_redist.x64).exe"
        }
    }
    if($osInfo.IsCore)
    {
        $filesToCopy+="vbrun60sp6.exe"
    }
    Write-Debug "filesToCopy=$filesToCopy"
    $filePathToCopy=$filesToCopy|ForEach-Object{Join-Path $PrerequisitesSourcePath $_}
    
    if($Computer)
    {
        if($PSVersionTable.PSVersion.Major -ge 5)
        {
            $targetPath=Get-ISHServerFolderPath
        }
        else
        {
            # Need a unc path to copy to remote server from PowerShell v.4
            $targetPath=Get-ISHServerFolderPath -UNC
        }
    }    
    else
    {
        $targetPath=Get-ISHServerFolderPath
    }

    Write-Debug "targetPath=$targetPath"

    if($Computer)
    {
        if($PSVersionTable.PSVersion.Major -ge 5)
        {
            Copy-Item -Path $filePathToCopy -Destination $targetPath -Force -ToSession $remote.Session
        }
        else
        {
            # Use the unc path
            Copy-Item -Path $filePathToCopy -Destination $targetPath -Force
        }
    }    
    else
    {
        Copy-Item -Path $filePathToCopy -Destination $targetPath -Force
    }

    Write-Verbose "Uploaded files to $targetPath"
}

finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
}

Write-Separator -Invocation $MyInvocation -Footer