
CONTENT
=======

1. Subfolder "CustomerSpecificFiles\FilesToCopy" holding prepared files (compare/merge for many) for a specific InfoShare version
1. Manifest.psd1 with right version and sub-files
1. Subfolder "Settings" holding deployment automation and transformation scripts.

FLOW
====

1. Prepare local environment (manual)
    1. Install vanilla installation of InfoShare
    1. Install matching ISHDeploy
    1. Install matching ISHRemote
    1. Install matching ISHBootstrap
    1. `New-ISHDeploymentConfiguration -Project this -Stage that` --> json configuration file
    1. `Set-ISHDeploymentFontoConfiguration -Project this -Stage that`
    1. Edit json configuration file adding Credentials, Intergations, Components, etc.
1. Extract Recipe (C:\recipe for example) so you have manifest.psd1 and CustomerSpecificFiles
1. Call `Set-ISHRoleComponentTags -ThisThat` to tag local system with desired components.
1. Call `Invoke-ISHDeploymentSequence -RecipeFolderPath C:\recipe` to execute deployment sequence.
