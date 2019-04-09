# Change log

## next release
- GH-107: Changes required for new 'ISHCS' web application (InstallTool inputparameters)
- GH-102: Database - Add the option to restore the Demo or and Empty database from the ISHCD as local/'mock' database
- GH-101: DevelopFriendly - Improve PowerShell scripts to help in troubleshooting instances
- GH-100: Update the example scripts to use the 'versionless' ISHDeploy module
- GH-97: DevelopFriendly - PowerShell scripts to help in troubleshooting instances (enhancement)
- GH-94: Add support for local SQL Server (Express) 2016 database for AWS (EC2) instances (enhancement)
- GH-92: Initialize-MockDatabase.ps1 - Support creation of a SQL user when initializing the mock database (enhancement)
- GH-89: Add support for Windows Server 2019
- GH-87: Restore support for local SQL Server Express database for Vagrant boxes (Hyper-V)
- GH-86: Make it possible to initialize an image with only the third party software prerequisites and/or the Application prerequisites and installation
- GH-85: Make sure that the minLevel of the File logger is set to 'Debug' for InstallTool
- GH-84: Add installation of AdoptOpenJDK and JRE pre-requisite
- GH-xx: Update valid/supported versions (released: 13.0.1, 13.0.2, not released 14.0.0).

## release v1.2

- GH-53: Add support for docker container images
- GH-78: Make ContentManager2018 the primary target

Remarks:
- Moved links from https://github.com/Sarafian to https://github.com/sdl .

## release v1.1

- GH-66: Allow parallel building of AMI and Vagrant boxes.
- GH-67: Auto calculate checksum for given ISO file.
- GH-70: Include changes for release of Knowledge Center 2016 SP4.

## release v1.0

- GH-54: Add support for Amazon Web Services EC2 AMI.
- GH-55: Add support for Vagrant boxes (Hyper-V).
- GH-53: Add support for docker container images.
- GH-58: Configure RequireSSL attribute for ISHCM and ISHSTS web applications. Script `Set-IISRequireSSL.ps1` is added.
- GH-50: Import ISHTemplate repository as a Builders folder. ISHBootstrap provides builder scripts for use with AWS EC2 AMI, Docker containers, Packer and Vagrant.
- GH-62: Use ISHServer cmdlets that manage the user profile

Known issues:

- GH-53: Add support for docker container images. Requires some fine-tuning

## pre-release v0.8

- GH-44: ISHBootstrap is not Set-StrictMode combatible.
- GH-45 and GH-46: Azure file and blob storage support. (Requires [ISHServer](https://github.com/Sarafian/ISHServer) version 1.2)
- GH-48: Allow override of input parameters when installing content manager.

## pre-release v0.7

- Added support for AWS S3 buckets. Requires [ISHServer](https://github.com/Sarafian/ISHServer) version 1.1
- [ISHServer](https://github.com/Sarafian/ISHServer) version 1.1 ISHCD provisioning is available. `Install-ISHDeployment.ps1` and `Uninstall-ISHDeployment.ps1` will calculate the cd's path.

## pre-release v0.6

- Removed supported for alternative ftp host. This was a hidden feature for internal SDL development.

## pre-release v0.5

- Removed **xISHServer** module from this repository and moved to [ISHServer](https://github.com/Sarafian/ISHServer).
- Fixed some issues with the `Restart-Server.ps1` and `Test-Server.ps1` scripts.

## pre-release v0.4

- All source code has header based on SDL's open source policy.
  - SDLDevTools module helps power `Test-OpenSourceHeaders.Tests.ps1` to safe guard SDL's open source policy.
- Dropped module **xISHInstall** and ported the code into **Install** scripts.    
- As the MSXML4 is not required for ISH
  - Removed `Install-ISHToolMSXML4` from **xISHServer.13**.
  - Script `Install-ISHServerPrerequisites.ps1` will invoke `Install-ISHToolMSXML4` only for version 12 and when parameter `-InstallMSXML` is specified. 
- Enhanced progress indicators in scripts.
- Refactored the WinRM secure initialization pipeline. No manual step is required on the remote server.
  - `Install-WinRMPrerequisites.ps1` 
  - `Enable-WSManCredSSP.ps1`
- New script `Install-certificate.ps1` installs a certificate.
- Renamed the `Invoke-Restart.ps1` to `Restart-Server.ps1`.
- New script `Test-Server.ps1` to check if a server is alive and can accept PowerShell remoting.
- Bug fixes.

## pre-release v0.3

**20161020**

- Changes in module **xISHServer**
  - Use new cmdlet `Get-ISHPrerequisites` for one of the following functions: 
    - Download the necessary files.
      - Initial supported method is with FTP.
    - Get the file names of the necessary files.
  - The cmdlet `Install-ISHToolAntennaHouse.ps1` will not set the license.
  - To add or update the Antenna House Formatter license use cmdlet `Set-ISHToolAntennaHouseLicense.ps1`
- Changes in scripts folder **xISHServer**
  - To seed the **xISHServer** module folder with the prerequisites:
    - Use **new** script `Get-ISHServerPrerequisites.ps1` and the **xISHServer** module will download the files. 
    - Use **updated** script `Upload-ISHServerPrerequisites.ps1`. Script uses the `Get-ISHPrerequisites` to know which files to copy.
  - Use **new** script `Set-ISHAntennaHouseLicense.ps1` to set the Antenna House Formatter license. 
  
## Before pre-release v0.2

**20161011**

- Major code refactoring. **Before** this all code expected to access and execute remote code without specifying credential. This worked for domain credentials. 
  - Improved the `Add-ModuleFromRemote.ps1` to accept a `-Credential` parameter. 
  - Improved the `Invoke-CommandWrap.ps1` to accept a `-Credential` parameter. 
  - All scripts accept a `-Credential` parameter.
- **xISHServer** is now smarter:
  - `Get-ISHOSInfo` breaks down the information from the caption of the operating system.
  - `Get-ISHNETInfo` returns .NET available .NET versions.
  - `Get-ISHCOMPlus` returns COM+ applications and their state.
  - `Test-ISHServerCompliance` checks if the target operating system is supported by this bootstrapper.
    - Windows Server 2016.
    - Windows Server 2012 R2.
    - Windows Server 10.
    - Windows Server 8.1 **not tested though**.
  - `Install-ISHVisualBasicRuntime` installs the Visual Basic Runtime SP6. Requires file `vbrun60sp6.exe`. Get it from [Service Pack 6 for Visual Basic 6.0: Run-Time Redistribution Pack (vbrun60sp6.exe)](https://www.microsoft.com/en-us/download/details.aspx?id=24417) and then extract. **Use only** with Windows Server 2016 core variant. **This is a workaround**. [More information](https://social.technet.microsoft.com/Forums/windowsserver/en-US/9b0f8911-07f4-420f-9e48-d31915f91528/msvbvm60dll-missing-in-core?forum=winservercore).    
  - Removed dependency to powershell module [Carbon](https://www.powershellgallery.com/packages/Carbon/2.3.0) by introducing alternatives.
    - Grant logon as privilege for a user. Added new `Grant-ISHUserLogOnAsService`.
    - Add user to local users group. Use `Add-LocalGroupMember` available on Windows PowerShell v.5.
- Script `Test-SupportedServer.ps1` checks if the target operating system is supported by this bootstrapper.

**Known Issues**

- When executing against a remote server that is not in the same domain, certain copy actions will not be supported when the client is powered by PowerShell v.4 because the `Copy-Item` doesn't accept specific credentials. 
  - `Upload-ISHServerPrerequisites.ps1` should work but not tested.

**20160908**

- Minor fixes and added new parameters for `Initialize-Remote.ps1`.

**20160905**

- 'Initialize-ISHServerOSUserRegion.ps1` fix to force the `osuser`'s profile to be initialized.
- Each script emits header and footer. (`Write-Separator.ps1`)

**20160830**

- 'Invoke-CommandWrap` fix for script blocks with param.

**20160819**

- Cmdlets of module **xISHInstall** require a deployment name instead of a suffix.
- All scripts add a verbose line with their invocation.

**20160818**

- Refactored the implicit remoting by using the new `Add-ModuleFromRemote` and `Remove-ModuleFromRemote`.
- Made installation of OracleODAC an optional part of the flow.
- Separated **Examples** specific changes from the main changelog.  

**20160816**

- In example 'Install-Module.ps1' when working locally, the script will load automatically from the source. No need to publish xISHServer or xISHInstall.
- New configuration scripts in examples. `Set-ISHSTSWindows.ps1` and `Set-UIFeatures.ImplicitRemoting.ps1` to enable the light weight windows authentication on top of ISHSTS. Scripts will make sure that IIS has the the module installed.
- Added `Clean-ISH.ps1` in examples to remove all artifacts. (The CD is not removed).

**20160729**

- Fixes to support non-remote execution.
- Introduced specific code path in `Initialize-ISHServer.ps1` to help with lengthy Fully Qualified Domain Name (FQDN) and implicit remoting.
- Install-ISHWindowsFeatures now works with both ServerManager and DISM modules. 

**20160727**

- New pipeline for ISHDeploy code as configuration scripts. Support for implicit remoting.
- Updated the `How to use the repository (Examples)` topic.

**20160725**

- Renamed ISHServer to xISHServer (Experimental).
- Improved topics.
- Added topic **How to use the repository**.

**20160720**

- Copy ISHCD script
- Script to assign certificate on IIS
- Script to install [ProcessExplorer](https://technet.microsoft.com/en-us/sysinternals/processexplorer.aspx).
- **Very** experimental/simplified automation of install/uninstall of ISH. Mostly focused on testing purposes.
- Moved the module dependency in the examples to one script `Install-Module`.
- Install ISHDeploy

**20160719**

- ISHServer module.
- Scripts to initialize server.

**20160718**

- Created mechanism for examples with test data indirection.
- Scripts to initialize PowerShellGet.
- Scripts to initialize remoting with CredSSP.

**20160712**

- Initial commit. Describing the repository.
