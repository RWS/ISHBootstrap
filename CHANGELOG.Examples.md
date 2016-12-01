# Examples Change log

## pre-release v0.4

- Support for upcoming internal releases of ISH.12.0.* in `Copy-ISHCD.NotReleased.ps1`.
- Updated scripts to match source's removal of **xISHInstall** module.  

## pre-release v0.3

**20161020**

- Adaptations in the scripts, json structure and how to topic to match the main codebase. 
  
## Before pre-release v0.2

**20161017**

- Due to ISHDeploy's upcoming cmdlet renaming and tutorial changes the `Set-ISHUIFeatures.ps1` was split into
  - `Set-ISHCMComponents.ps1`
  - `Set-ISHCMMenuAndButton.ps1`

**20161011**

To align with the major changes in Source:

- Added new supported property in JSON `CredentialExpression` that drives authorization for all remote calls.
- `Initialize-ISHServer.ps1` checks if the target operating system is supported by this bootstrapper.
- Improved the configuration scripts
  - When the value is localized, the value is read from the json file
  - Changes in the required parameters for each configuration script. Check [How to use the repository (Examples)](Topics\How to use the repository (Examples).md)
  - Split the ADFS integration in two files 
    - `Set-ISHIntegrationADFS.ps1` configures the ADFS artifacts on ISH.
    - `Set-ADFSIntegrationISH.ps1` configures the ISH artifacts on ADFS. **Knownissue** when the remote ish server is not in the same domain as with the client. The implicit variant **works**.
  - `Set-InternalAuthentication.ps1` enables the internal authentication flow.
  - `Set-ISHSTSRelyingParty.ps1` adds relying parties to ISHSTS.
  - `Set-ISHSTSWindows.ps1` enables windows authentication on ISHSTS.

**Known Issues**

- When executing against a remote server that is not in the same domain, certain copy actions will not be supported when the client is powered by PowerShell v.4 because the `Copy-Item` doesn't accept specific credentials. 
  - `Set-ADFSIntegrationISH.ImplicitRemoting.ps1` will break
  
  
**20160908**

- New json parameter supported for `Initialize-Remote.ps1`.

**20160902**

- `Invoke-Pester.ps1` will output also the test result file path. File format is by default `NUnitXml` but it can be changed.

**20160901**

- Code as configuration scripts output a header/footer to improve console readability.

**20160826**

- `Load-ISHBootstrapperContext.ps1` can load a context from a variable with a pre-loaded json.

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