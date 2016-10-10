# Change log

**20161010**

- Major code refactoring. **Before** this all code expected to access and execute remote code without specifying crendetial. This worked for domain credentials. 
  - Impoved the `Add-ModuleFromRemote.ps1` to accept a `-Credential` parameter. 
  - Impoved the `Invoke-CommandWrap.ps1` to accept a `-Credential` parameter. 
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
  - Removed dependency to powershell module [Carbon](https://www.powershellgallery.com/packages/Carbon/2.3.0) by introducing altetnatives.
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
- Seperated **Examples** specific changes from the main changelog.  

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
- **Very** experimental/simlified automation of install/uninstall of ISH. Mostly focused on testing purposes.
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