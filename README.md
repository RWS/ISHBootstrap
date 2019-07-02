# ISHBootstrap
Bootstrapper for deployments of [SDL Tridion Docs](https://sdl.com/xml) Content Manager (Knowledge Center Content Manager, LiveContent Architect, Trisoft InfoShare)

# Description

For those who don't like repetitive tasks, this repository is all about automating the deployment of [SDL Tridion Docs](https://sdl.com/xml) Content Manager.
[SDL Tridion Docs](https://sdl.com/xml) Content Manager is also known under its historical product names Knowledge Center Content Manager, LiveContent Architect, Trisoft InfoShare.

ISHBootstrap gives you the ability to bootstrap a clean Windows Server (bare metal, virtualized, cloud) and turn it into a fully operational Content Manager (ISH) deployment.
The bootstrapping can be executed locally or against a remote server using Windows remoting.
The supported operating systems are Windows Server 2012R2, 2016, 2019.

[How to use the repository (Examples)](Tutorials/How%20to%20use%20the%20repository%20(Examples).md) showcases how the complete process could look like, driven by a json file. 
But keep in mind that this is just an example.

[How to use the repository (Builders)](Tutorials/How%20to%20use%20the%20repository%20(Builders).md) explains how to use the 'builders' to build artifacts such as Amazon Web Services (AWS) EC2 AMI or Hyper-V Vagrant boxes.

# Goal 
With the ISHBootstrapper the following flow gets automated for a clean/default Windows Server 2016 installation

1. Enable and configure the **WinRM** (Windows Remoting) for secure connections and `CredSSP`
1. Install Content Manager prerequisites as described in the [documentation](https://docs.sdl.com/LiveContent/web/pub.xql?action=home&pub=SDL%20Knowledge%20Center%20full%20documentation-v3&lang=en-US)
1. Copy the deliverable of the Content Manager CD
1. Install Content Manager. One or more deployments.
1. Execute [ISHDeploy](https://powershellgallery.com/packages/ISHDeploy/) based code as configuration scripts

Do all of the above with minimum manual actions and all should work locally and remotely. 
At the end the dream goal is to execute a seamless update of a Content Manager deployments   

**Remarks**:

- Typically a Content Manager deployment is deployed on a server already part of Active Directory. 
For this reason, some remote instructions fill face the double hop limitation described in [Powershell Remoting Caveats](https://sarafian.github.io/2016/07/05/remoting-caveats.html) and to work around the problem sessions with `CredSSP` will be required.
- Not all modules available here will be published to PowerShell gallery. Setting up an internal nuget repository is easy. The process is described [here](https://docs.nuget.org/create/hosting-your-own-nuget-feeds).
- To avoid revealing internal asset names some variables will not be defined in code but we'll be acquired with cmdlets such as `Get-Variable`

# Using the repository

As mentioned before some tutorials are provided in the [Tutorials](Tutorials) folder.

# Future

If you can fully automate the delivery of a deployment then you can trigger this from any Continuous Integration (CI) system. 
Potential targets of a trigger can be:

- Deliver a collection of servers.
- Spin up a server on demand and then take it down.
- Spin up a environment for full client/api/data testing and then take it down.