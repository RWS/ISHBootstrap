# ISHBootstrap: The Module

Up until now, ISHBootstrap was just a collection of PowerShell scripts and examples to automate the installation of Tridion Docs. 
Starting from the preparation of the OS, the OS users, the installation of third party prerequisites (using [ISHServer](https://github.com/sdl/ISHServer)) up to an OOTB/Vanilla installation of Tridion Docs ([README_ISHBootstrap_Scripts.md](./README_ISHBootstrap_Scripts.md)).

It only included some basic configuration/customization examples (using [ISHDeploy](https://www.powershellgallery.com/packages/ISHDeploy)). 
We now added an **ISHBootstrap PowerShell Module**, to introduce a **common standard way of:** 

- **Specifying the intent of your Tridion Docs deployment** 
- **Organizing your configuring/customizing scripts**
- **Applying your configuration/customization scripts**

The module is not focused on cmdlets to configure/customize Tridion Docs, but on organizing and sequencing the configuration/customization scripts.

Over time, the initial scripts and examples to automate the installation of Tridion Docs will also be incorporated in the PowerShell module, but **for now the ISHBootstrap PowerShell Module is focused on the configuration/customization of Tridion Docs.**


# ISHBootstrap: Some Concepts
We first want to introduce the high level concepts of this standardized way of  configuring/customizing Tridion Docs.

## The Starting Point

Before you start using the ISHBootstrap Module to configure/customize Tridion Docs, we assume you have:

- A working OOTB/Vanilla Tridion Docs installation (manually installed or using ISHBootstrap/ISHServer or ...).
- Installed all PowerShell Modules ISHBootstrap depends on (Install-ISHBootstrapPrerequisites.ps1)

## The Deployment Configuration

Some minimal information is needed to drive the automated configuration/customization of Tridion Docs. The ISHBootstrap Module contains cmdlets to create that configuration file.

## The Roles and Components

The ISHBootstrap Module also provides cmdlets to tag a Tridion Docs server with a certain **Role**. That role determines, which Tridion Docs **Components** need to be configured, enabled and/or started on that Tridion Docs server.
ISHBootstrap provides cmdlets to:

- Tag a system with a certain Role and it's Components
- Test if a server is tagged with a certain Role and/or Component.

Using these Role and Components as a condition in your scripts to configure/customize Tridion Docs, makes them for instance portable across the different stages of a Tridion Docs deployment, e.g. from development (one server) to staging, production (multiple servers).  

## The Deployment Sequence

The ISHBootstrap Module provides a cmdlet to **start the configuration/customization of Tridion Docs in a certain standardized sequence**. During the execution of this sequence, entry-points/hooks are foreseen that can execute certain specific configuration/customization scripts you developed.

## IMPORTANT
Up until now, we did not do anything to actually make changes to the configuration or to customize Tridion Docs. We just agreed and standardized on:

1. The starting point
2. The configuration
3. The roles/components
4. The deployment sequence

The actual configuration/customization is done in the next most important part. The implementation of the Recipe

## The Recipe

The **Recipe** is **a standardized, pre-defined, structured collection of scripts and resources that hook into the Deployment Sequence**. It provides template scripts where your specific configuration and customization code or scripts can be added or included in a particular step of the sequence.

The ISHBootstrap module contains a cmdlet to create an 'empty' Recipe which you can use to start implementing your custom Recipe.

# ISHBootstrap: How To Use The Module

 Detailed information on how to use the ISHBootstrap PowerShell Module can be found in the [HOWTO.md](./HOWTO.md).