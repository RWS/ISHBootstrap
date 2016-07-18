param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$false)]
    [switch]$ReInstall=$false
)        

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"
. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$packageManagementScriptBlock={
    if($PSVersionTable.PSVersion.Major -ge 5)
    {
        Write-Verbose "PowerShell v5 found. Skipping"
        return
    }

    if(Get-Command Install-Package -ErrorAction SilentlyContinue)
    {
        if(-not $ReInstall)
        {
            Write-Verbose "PackageManagement module is installed"
            return
        }
        else
        {
            Write-Verbose "PackageManagement module will be reinstalled"
        }
    }
    $msiName="PackageManagement_x64.msi"
    $downloadUrl="https://download.microsoft.com/download/C/4/1/C41378D4-7F41-4BBE-9D0D-0E4F98585C61/PackageManagement_x64.msi"
    $msiPath="$env:USERPROFILE\Downloads\$msiName"

    Write-Debug "Downloading $downloadUrl to $msiPath"
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($downloadUrl, $msiPath)
    Write-Verbose "Downloaded $downloadUrl"

    $logFile=Join-Path $env:TEMP "$msiName.log"
    Write-Debug "Installing $msiPath"
    Start-Process $msiPath -ArgumentList @(“/qn”,"/lv",$logFile) -Wait
    Write-Verbose "Installed $msiPath"
}

#Install the packages
try
{
    Invoke-CommandWrap -ComputerName $Computer -ScriptBlock $packageManagementScriptBlock -BlockName "PackageManagement" -UseParameters @("ReInstall")
}
catch
{
    Write-Error $_
}



