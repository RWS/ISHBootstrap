# Examples Change log

**20160825**

- `Invoke-ISHDeployScript.ps1` and `Invoke-Pester.ps1` will skip script references that do not exist. Temporary commenting mechanism.
- New `Invoke-Pester.ps1` to execute pester tests.

**20160819**

- Script `UnInstall-ISH.ps1` first tries to use **ISHDeploy** and then falls back into looking for input parameter files droped by  `Install-ISH.ps1`.
- Scripts are now powered by deployment names instead of suffix.
- Scripts that seed the ISHCD have now two permutations `Copy-ISHCD.Released.ps1` and `Copy-ISHCD.NotReleased.ps1`.
  - `Copy-ISHCD.NotReleased.ps1` is for internal releases. This is for **internal** use only.
  - `Copy-ISHCD.Released.ps1` is powered by an FTP. 

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