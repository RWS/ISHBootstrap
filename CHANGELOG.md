# Change log

**20160818**

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