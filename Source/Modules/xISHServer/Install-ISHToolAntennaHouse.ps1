. $PSScriptRoot\Get-ISHServerFolderPath.ps1

function Install-ISHToolAntennaHouse
{
    <# Not working with parameters
    http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-6CC6D7ED-9319-4FA6-998D-B6D241ACBF75
    Cannot automate. Everything seems to execute but no installation what so ever
    Tried http://stackoverflow.com/questions/11421306/installshield-silent-uninstall-not-working-at-command-line
    Tried http://www.itninja.com/blog/view/installshield-setup-silent-installation-switches
    #>

    <# Workign with IIS files .
    Recommendation by Jered Bastinck <jbastinck@sdl.com>.
    Quote from his email
    I recommend to install Visual C++ 2010 prior installing AntennaHouse. This is a prereq of Antennahouse and I’ve seen different results if this is not installed (the installer is trying to install it for you but the user has to accept the Microsoft Agreement)

    Steps:

    1.	Create an setup answer file: example: V6-3-R1a-Windows_X86_32E.exe –r
    2.	File is created in the Windows folder: setup.iss
    3.	Copy this file in the same location as the AntennaHouse installer
    4.	Execute V6-3-R1a-Windows_X86_32E.exe /S /f1.\setup.iss
    5.	AntennaHouse is automatically installed
    #>

    

    
    $fileName="V6-2-M9-Windows_X64_64E.exe"
    
    #Before installing Antenna houe we need to install the Microsoft Visual C++ 2010. Minimum version must be 10.0.40219.1
    Write-Verbose "Need to install Microsoft Visual C++ 2010 as a prerequisite"

    @("$fileName.vcredist_x64.exe","$fileName.vcredist_x86.exe") | ForEach-Object {
            $vcFileName=$_
            $filePath=Join-Path (Get-ISHServerFolderPath) $vcFileName
            $logFile=Join-Path $env:TEMP "$vcFileName.htm"
            $arguments=@(
                "/q"
                "/log"
                "$logFile"
            )
            Write-Debug "Installing $filePath and logging to $logFile"
            Start-Process $filePath -ArgumentList $arguments -Wait -Verb RunAs
            Write-Verbose "Installed $vcFileName"
    }


    #Install Antenna House
    $issPath=Join-Path (Get-ISHServerFolderPath) "$fileName.iss"
    $filePath=Join-Path (Get-ISHServerFolderPath) $fileName
    $logFile=Join-Path $env:TEMP "$FileName.log"
    $arguments=@(
        "/s"
        "/f1$issPath"
        "/f2$logFile"
    )

    Write-Debug "Installing $filePath using $issFilePath and logging to $logFile"
    Start-Process $filePath -ArgumentList $arguments -Wait -Verb RunAs
    Write-Verbose "Installed $fileName"
}