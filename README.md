# ISHBootstrap
Bootstrapper for [SDL Knowledge Center](https://sdl.com/xml) Content Manager deployments

# Description

For those who don't like repetitive tasks, this repository is all about automating the deployment of [SDL Knowledge Center](sdl.com/xml) Content Manager.
[SDL Knowledge Center](sdl.com/xml) Content Manager is also known as with historical names ~~Trisoft~~, ~~InfoShare~~ or as we recently established **ISH**.

I initially started this codebase as my own internal automation for a lab that I use to experiment with [ISHDeploy](https://sarafian.github.io/tags/ishdeploy/). 
This repository is a port of that code base combined with some effort to improve it.

# Goal 
With the ISHBootstrapper the following flow gets automated for a clean/default Windows Server 2012 R2 installation

1. Install the `PowerShellGet` powershell module to easily install modules. Windows Server 2012 R2 offers out of the box Powershell v4.0. Content Manager 12.0.* supports version v4.0.
1. Enable and configure the **WinRM** (Windows Remoting) for secure connections and `CredSSP`
1. Install Content Manager prerequisites as described in the [documentation](https://docs.sdl.com/LiveContent/web/pub.xql?action=home&pub=SDL Knowledge Center full documentation-v2&lang=en-US)
1. Copy the deliverable of the Content Manager CD
1. Install Content Manager. One or more deployments.
1. Execute [ISHDeploy](powershellgallery.com/packages/ISHDeploy.12.0.0/) based code as configuration scripts

Do all of the above with minimum manual actions and all should work locally and remotely. 
At the end the dream goal is to execute a seamless update of a Content Manager deployments   

**Remarks**:

- Typically a Content Manager deployment is deployed on a server already part of Active Directory. 
For this reason, some remote instructions fill face the double hop limitation described in [Powershell Remoting Caveats](https://sarafian.github.io/post/powershell/powershell-remoting-caveats/) and to work around the problem sessions with `CredSSP` will be required.
- Not all modules available here will be published to PowerShell gallery. Setting up an internal nuget repository is easy. The process is described [here](https://docs.nuget.org/create/hosting-your-own-nuget-feeds).
- The code base will work against current **Knowledge Center 2016 Content Manager 12.0.0** but the code base will support future minor releases like **Knowledge Center 2016 Content Manager 12.0.1** and future major releases that is only internally available.
- To avoid revealing internal asset names some variables will not be defined in code but we'll be acquired with cmdlets such as `Get-Variable`

# Using the repository

Tutorials are also provided in [Tutorials](Tutorials) folder.

# Future

If you can fully automate the delivery of a deployment then you can trigger this from any Continuous Integration (CI) system. 
Potential targets of a trigger can be:

- Deliver a collection of servers.
- Spin up a server on demand and then take it down.
- Spin up a environment for full client/api/data testing and then take it down.

# Acknowledgements

This a **personal** effort and by **no means** reflects an official deliverable for [SDL](sdl.com). 
