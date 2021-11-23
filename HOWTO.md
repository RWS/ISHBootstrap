# ISHBootstrap: How To Use The Module

This document gives more detailed information on the different concepts, cmdlets and parameters of the ISHBootstrap PowerShell Module. 

# 1. The Deployment Configuration

Example cmdlet with the minimal parameters to create a deployment configuration file:

`New-ISHDeploymentConfiguration -Project customer1 -Stage dev1403`

The top-level **Project**, can have multiple **Stages**. You could say that a Project can correspond to a customer (customer1) and the Stages correspond to different Tridion Docs environments for that customer, like for instance: Development, Acceptance, Production.

In our example the Project is customer1 and the stage is dev1403 (e.g. Development environment for Tridion Docs 14.0.3).
When you run this cmdlet on the  server where an OOTB/Vanilla Tridion Docs is installed, some parameters are fetched from the current deployment (using ISHDeploy) and use it in the configuration file.
Like for instance the Tridion Docs version (ISHVersion), `Get-ISHDeploymentParameters -Name softwareversion`

Example output:

```
{
  "ISHBootstrap.2.0.0": {
    "Project": {
      "customer1": {
        "dev1403": {
          "Description": "Deployment stack configuration for project customer1 on stage allinone1403 for hostname ish1403-ws2019 .",
          "Hostname": "ish1403-ws2019",
          "ISH": {
            "ProductVersion": "14.0.3",
            "Integration": {
              "Database": {
                "SQLServer": {
                  "Username": "dbusername",
                  "DataSource": "(local)",
                  "InitialCatalog": "(local)",
                  "Password": "dbpwd",
                  "Type": "sqlserver2017"
                }
              }
            },
            "Component": {
              "BackgroundTask-Default": {
                "Count": 1
              },
              "Crawler": {
                "Count": 1
              },
              "TranslationBuilder": {
                "Count": 1
              },
              "TranslationOrganizer": {
                "Count": 1
              }
            }
          }
        }
      }
    }
  }
}
```
 In addition, you can run specific cmdlets to specify that certain features need to be enabled during deployment.
Currently this only supports the DraftSpace/ReviewSpace feature.

The following cmdlet will update the configuration with parameters to enable DraftSpace, DocumentHistoryForDraftSpace and ReviewSpace

`Set-ISHDeploymentFontoConfiguration -Project customer1 -Stage dev1403 -DraftSpace -DocumentHistoryForDraftSpace -ReviewSpace -DocumentHistoryForReviewSpace`

Additional cmdlets are available to set certain parameters explicitly.

# ISHBootstrap: The Roles and Components

The **Roles** and matching Tridion Docs **Components** are used to describe which part of the Tridion Docs services need to be configured and enabled/started when working in a distributed environment (typical Frontend servers and Backgroundtask servers).

An example of the most basic role is the **AllInOne** role. This means that this Tridion Docs server will be tagged with all Tridion Docs Components, meaning that all these components will be enabled and/or started on this server.

`Set-ISHRoleComponentTags -AllInOne`

Using these 

`Test-ISHComponent -Name FullTextIndex`

# ISHBootstrap: The Deployment Sequence

`Invoke-ISHDeploymentSequence`

# ISHBootstrap: The Recipe

The Recipe is a pre-defined, structured collection of scripts and resources, containing custom PowerShell scripts that represent a specific configuration/customization.


## The Recipe Template

The ISHBootstrap module contains a cmdlet to create an 'empty' recipe from a template included in ISHBootstrap.

`New-ISHDeploymentRecipe -ProjectName sdldoc -RecipeName sdldoc1403 -RecipeVersion 0.0.1`

In the root folder of the recipe, there must be the `manifest.psd1` that describes how the recipe interacts with ISHBootstrap during the deployment.
This is the **CONTRACT** between ISHBootstrap and your recipe.



```
@{
    # Manifest type
    Type="ISHRecipe"
    # Manifest version (<> recipe version)
    Version="1.0.0"

    # Metadata
    Name=""
    Version=""
    Author=""
    CompanyName=""
    Copyright=""
    Description=""
    
    # Prerequisites
    Prerequisite=@{
        Version=@{
            Major=""
            Minor=""
            Build=""
            Revision=""
        }
    }
    
    # Scripts.
    Scripts=@{
        PPreRequisite="Test-PreRequisite.ps1"
    
        Stop=@{
            BeforeCore="Stop-BeforeCore.ps1"
            AfterCore="Stop-AfterCore.ps1"
        }
    
        Execute="Invoke-Recipe.ps1"
    
        DatabaseUpgrade=@{
            BeforeCore=""
            AfterCore=""
        }
    
        DatabaseUpdate=@{
            BeforeCore="Invoke-DatabaseUpgradeBeforeCore.ps1"
            AfterCore="Invoke-DatabaseUpgradeAfterCore.ps1"
        }
    
        Start=@{
            BeforeCore="Start-BeforeCore.ps1"
            AfterCore="Start-AfterCore.ps1"
        }
    
        Validate="Test-Validate.ps1"
    }
}
```



*   **The Type**
    ISHRecipe: This identifies the manifest and the folder as a Docs Recipe.
*   **The Version**
    This is the version of the recipe template/manifest. **Not** the version of the Recipe?
*   **The Metadata
    **Informational only. Not used in scripts.
*   **The `Prerequisite`**
    Describes hard dependencies for the recipe. To describe the Docs version dependency, the `Major` value is required.
    **Note:** the comparisons are based on equality and not less or greater than.
    If specified, this is always validated before any script is executed.
*   **The Scripts**
    References scripts that ISHBootstrap will execute during the deployment. Each script entry is optional and it's value should be relative to the manifest's location.
    More details in next sections.

## The Recipe Scripts Sequences

The scripts referenced in the different 'Scripts' steps are executed in the following sequence:

1.  **Stop** (ApplicationStop)
    1.  Scripts.PreRequisite: Test-PreRequisite.ps1
    2.  Scripts.Stop.BeforeCore: Stop-BeforeCore.ps1
    3.  Stop.Core (ISHBootstrap internal)
    4.  Scripts.Stop.AfterCore: Stop-AfterCore.ps1
2.  **'AfterInstall'**
    1.  Scripts.PreRequisite: Test-PreRequisite.ps1
    2.  Scripts.Execute: Invoke-Recipe.ps1
        **If the `DatabaseUpgrade` component is found,**
        **Upgrade the database:** the internal structure of the target database is being upgraded to match the Docs version. For example changes in tables, columns etc but also in fields, cards etc)
    3.  Scripts.DatabaseUpgrade.BeforeCore: Invoke-DatabaseUpgradeBeforeCore.ps1
    4.  DatabaseUpgrade.Core (ISHBootstrap interrnal)
    5.  Scripts.DatabaseUpgrade.AfterCore: Invoke-DatabaseUpgradeAfterCore.ps1
        **If the `DatabaseUpgrade` component is found,**
        **Update the database:** changing values in the database such as XML in central configuration, updating templates etc. This requires the ISHWS web services to be operational. Use the ISHRemote module for updatedes. You can use `New-ISHWSSession` to acquire an authenticate session for ISHRemote.
    6.  Scripts.DatabaseUpdate.BeforeCore: Invoke-DatabaseUpdateBeforeCore.ps1
    7.  DatabaseUpdate.Core (ISHBootstrap internal)
    8.  Scripts.DatabaseUpdate.AfterCore: Invoke-DatabaseUpdateAfterCore.ps1
3.  **Start** (ApplicationStart)
    1.  Scripts.PreRequisite: Test-PreRequisite.ps1
    2.  Scripts.Start.BeforeCore
    3.  Start.Core (ISHBootstrap internal)
    4.  Scripts.Start.AfterCore
4.  **Validate** (ValidateService)
    1.  Scripts.PreRequisite: Test-PreRequisite.ps1
    2.  Validate.Core (ISHBootstrap internal)
    3.  Scripts.Validate: Test-Validate.ps1

**Important:** Scripts.PreRequisite and Scripts.Validate should throw when prerequisites are not met or the validation fails.

## The Recipe Scripts In Detail

This section describes the kind and/or examples of configuration/customization scripts that can and/or need to be executed in a step of the deployment sequence.</span>

### PreRequisite: Test-PreRequisite.ps1

Make sure that the recipe is run in an environment that is matching what is expected. When not, an exception should be thrown and the execution is rejected and the entire deployment is also rejected/stopped.

### Stop.BeforeCore: Stop-BeforeCore.ps1

Stop any custom process before stopping the deployment’s processes

### Stop.AfterCore: Stop-AfterCore.ps1

Stop any custom process after stopping the deployment’s processes

### Execute: Invoke-Recipe.ps1

The main customization actions. The deployment is stopped, so ISHWS (the web service) is not available.

**Use ISHDeploy** when possible to change (configuration) files.

Try to script delta’s when possible, if file replacements are necessary, include a CustomerSpecificFiles folder in the recipe and use the **Copy-ISHFile cmdlet of ISHDeploy** to copy them.

```
$customerSpecificFilesToCopy = "$PSScriptRoot\CustomerSpecificFiles\FilesToCopy"
Copy-ISHFile  -ishCD $customerSpecificFilesToCopy -Force -Verbose
```


This is also the place where customizations to DITA-OT can be made.
Like:

*   copy the OOTB infoshare DITA-OT folder
*   download specific DITA-OT version and copy the customizations
*   copy custom DITA-OT include in the recipe

### DatabaseUpgrade.BeforeCore: Invoke-DatabaseUpgradeBeforeCore.ps1

Take any actions before the deployment’s database is upgraded (DBUpgradeTool) to match the deployed Docs version.

**This script is only run on instances that are tagged with the component: DatabaseUpgrade**

### DatabaseUpgrade.AfterCore: Invoke-DatabaseUpgradeAfterCore.ps1

Take any actions after the deployment’s database is upgraded (DBUpgradeTool). For example add fields, LOVs, etc.

Run DBUpgradeTool, with the -setup option to add fields, LOVs, ...
**Use ISHDeploy** to get the location of DBUpgradeTool (AppPath/...) and other deployment parameters.

**This script is only run on instances that are tagged with the component: DatabaseUpgrade**

### DatabaseUpdate.BeforeCore: Invoke-DatabaseUpdateBeforeCore.ps1

Take any actions before the deployment’s database is updated by DatabaseUpgrade.Core (internal), e.g. XML Settings etc

Be aware that for cloud deployments, changes can be made to the XML Settings to comply with the scale-out type used.

**This script is only run on instances that are tagged with the component: DatabaseUpgrade**

### DatabaseUpdate.AfterCore: Invoke-DatabaseUpdateAfterCore.ps1

Take any actions after the deployment’s database is updated by DatabaseUpgrade.Core (internal), e.g. XML Settings etc

Try to script delta’s when possible, since for cloud deployments, changes can be made to the XML Settings to comply with the scale-out type used.

**This script is only run on instances that are tagged with the component: DatabaseUpgrade**

### Start.BeforeCore
Start any custom process before starting the deployment’s processes

### Start.AfterCore

Start any custom process after starting the deployment’s processes

### Validate: Test-Validate.ps1

Core tests have already succeeded, like:

*   Status of COMPlus
*   Status of IIS
*   Availability and authentication for the web site
*   Availability and authentication for the web services (asmx and svc)

Adding you own validation tests, will safe guard that the instance is configured and customised as intended.

You can use for instance Pester to validate the deployment. When the tests fail, then the script throws to stop the execution.

`$pesterRecipeScripts=@(`
    `Resolve-Path -Path "./Test-1.ps1"`
    `Resolve-Path -Path "./Test-2.ps1"`
`)`

`$pesterRecipeResult=Invoke-Pester -Script $pesterRecipeScripts -PassThru`
`if($pesterRecipeResult.FailedCount -gt 0)`
`{`
    `throw "$($pesterRecipeResult.FailedCount) recipe tests failed"`
`}`

## Invoking The Deployment

The following cmdlet will execute the full deployment sequence and the code/scripts you implemented in the hooks of the Recipe.

```
Invoke-ISHDeploymentSequence -RecipeFolderPath C:\Provision\Recipe\ 
```

Table with Deploymentstep, hook and matching script in the Recipe template:

![](.\ISHBootstrap_Recipe.svg)