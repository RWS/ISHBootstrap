# Examples Change log

**20160818**

- Scripts using implicit remoting are refactored to leverage the `Add-ModuleFromRemote` and `Remove-ModuleFromRemote`.
- Scripts will install OracleODAC only when `InstallOracle` is defined in the json file.
- Seperated **Examples** specific changes from the main changelog.  

**20160816**

- In example 'Install-Module.ps1' when working locally, the script will load automatically from the source. No need to publish xISHServer or xISHInstall.
- New configuration scripts in examples. `Set-ISHSTSWindows.ps1` and `Set-UIFeatures.ImplicitRemoting.ps1` to enable the light weight windows authentication on top of ISHSTS. Scripts will make sure that IIS has the the module installed.
- Added `Clean-ISH.ps1` in examples to remove all artifacts. (The CD is not removed).

**20160727**

- Removed topic `About example script`