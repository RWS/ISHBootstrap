# How to use the repository (Examples)

Starting from a clean **Windows Server 2012 R2** installation this how you end up with a [SDL Knowledge Center 2016](sdl.com/xml) Content Manager 12.0.0 Deployment.

# Acknowledgements

- The target computer name is `SERVER01` and is initialized with **Windows Server 2012 R2** and is already joined in a active directory domain.
- We'll use a domain certificate server to issue certificates. This is similar to the *Create Domain Certificate...* in **Internet Information Services (IIS) Manager**.
- **osuser** and **ospassword** are the credentials used in the **Content Manager** installation input parameters to specify which user runs the services. The osuser must be member of the local administrator group.
- Dependency to PowerShell modules on gallery
  - [CertificatePS](http://www.powershellgallery.com/packages/CertificatePS/). This is used to help with certificate templates. Read more about this [here](https://github.com/Sarafian/CertificatePS)
  - [Carbon](http://www.powershellgallery.com/packages/Carbon/). This is used to add the osuser to the local administrator group.
  - [PSFTP](http://www.powershellgallery.com/packages/PSFTP/). This is used to download files from an ftp server
  - [ISHDeploy.12.0.0](http://www.powershellgallery.com/packages/ISHDeploy.12.0.0/). This is used to download files from an ftp server
- Dependency to PowerShell modules in this repository. The following modules must be published to an internal NuGet server. The target server
  - xISHServer.12. This module helps installs all *ISH* prerequisites as described in the online [documentation](http://docs.sdl.com/LiveContent/web/pub.xql?action=home&pub=SDL%20Knowledge%20Center%20full%20documentation-v2&lang=en-US#docid=GUID-2AB53FDA-E9CB-4D46-A393-EEE6CF256554&addHistory=true&query=&scope=&tid=&filename=&resource=&inner_id=&toc=false&eventType=lcContent.loadDocGUID-2AB53FDA-E9CB-4D46-A393-EEE6CF256554)
  - xISHInstall. This module is a wrapper for simple cmdlets that install/uninstall a Content Manager. This allows easily to install/uninstall remotely.

To quickly host an internal NuGet server follow the instructions in this [article](https://docs.nuget.org/create/hosting-your-own-nuget-feeds). 
Once the server is up you need to register the repository on your system while specifying the both the `-SourceLocation` and `PublishLocation` parameters. 
In this example the name of the repository is `asarafian`.
  
# Steps

The process depends on scripts in the examples directory. To help run these scripts we need to use a json file that drives the files. Read more [About Example Scripts](About Example Scripts.md)

1. Publish the repository modules to an internal NuGet Server (asarafian).
1. Initialize PowerShellGet on remote server.
  1. Install PackageManagement
  1. Update the NuGet package provider.
  1. Register a repository for `asarafian`.
1. Install all modules
1. Enable the CredSSP authentication for PSSession. 
1. Install the server prerequisites using xISHServer.12
1. Seed the server with a Content Manager CD.
1. Install a deployment using xISHInstall.
1. Apply code as configuration scripts using ISHDeploy.12.0.0


## Publish the modules to the internal Nuget Server repository

```powershell
& .\Source\Modules\Publish-xISHServer.ps1 -ModuleName xISHServer.12 -Repository asarafian -APIKey asarafian -BuildNumber -TimeStamp
& .\Source\Modules\Publish-xISHServer.ps1 -ModuleName xISHServer.13 -Repository asarafian -APIKey asarafian -BuildNumber -TimeStamp
& .\Source\Modules\Publish-xISHInstall.ps1 -Repository asarafian -APIKey asarafian -BuildNumber -TimeStamp
```

Because the repository is internal we force a very detailed build number on the module version using `-BuildNumber` and `-TimeStamp`. 
This allows a repeative publish as ofter as we want.

## Load the data container json file

```powershell
& .\Examples\Load-ISHBootstrapperContext.ps1 -JSONFile "server01.json"
```

An obfuscated file looks like this
```json
{
  "ComputerName": "SERVER01",
  "ISHVersion": "12.0.0",
  "EnableSecureWinRM": true,
  "CertificateAuthority" : "CertificateAuthority",
  "InstallProcessExplorer": true,
  "xISHServerRepository": "asarafian",
  "xISHInstallRepository": "asarafian",
  "ISHDeployRepository": "PSGallery",
  "PrerequisitesSourcePath": "C:\\inetpubopen\\xISHServer",
  "CredentialForCredSSPExpression": "New-MyCredential",
  "OSUserCredentialExpression": "New-InfoShareServiceUserCredential",
  "PSRepository": [
    {
      "Name": "asarafian",
      "SourceLocation": "http://mymachine/MiniNuGetServer/nuget/",
      "InstallationPolicy": "Trusted"
    }
  ],
  "FTP": {
    "Host": "host"
    "User": "user",
    "Password": "password",
    "ISH1200CDFolder": "path",
    "ISH1200CDFileName": "filename"
  },
  "ISHDeployment": [
	{
	  "Suffix": "SQL",
	  "IsOracle": false,
	  "ConnectionString": "",
	  "LucenePort": 9010,
	  "UseRelativePaths": false,
	  "Scripts": [
		"ISHDeploy\\Set-UIFeatures.ps1",
		"ISHDeploy\\Set-ADFSIntegration.ps1"
	  ]
	}
  ]
}
```

An explanation about the structure of the json is available on [About Example Scripts](About Example Scripts.md). 

## Initialize PowerShellGet on remote server

```powershell
& .\Examples\Initialize-PowerShellGet.ps1
```

This step uses the `PSRepository` list from the json. Make sure you have the correct values.
As part of this step, [ProcessExplorer](https://technet.microsoft.com/en-us/sysinternals/processexplorer.aspx) will be installed when `InstallProcessExplorer` is `true`. I just like ProcessExplorer and find it usefull when troubleshooting this repository.

## Install all modules

```powershell
& .\Examples\Install-Module.ps1
```

This step uses the `xISHServerRepository`,`` and `ISHDeployRepository` to install the modules from the matching repository name. In this example the internal repository is specified by `asarafian` name in `PSRepository`.

## Enable the CredSSP authentication for PSSession

```powershell
& .\Examples\Initialize-ServerForRemote.ps1
```

This step uses the `EnableSecureWinRM` and when set to `true` at the end of this step there is a prompt that looks like this

> Login to  and execute locally C:\Users\username\Documents\WindowsPowerShell\Initialize-Remote.ps1

The required certificate for the Secure WinRM is issued by the domain certificate authority, effectively making it a double hop. More about the issue [PowerShell Remoting Caveats](https://sarafian.github.io/post/powershell/powershell-remoting-caveats/). 
To configure the system at this moment we need to Remote Desktop and execute locally. I understand that there are alternatives but I'm not a hard core ops engineer and my knowledge about the Windows operating system stops beyond this point.

**Important to notice** is that this steps creates a web server certificate that is used later on the HTTPS binding on IIS. If you skip this step then the certificate must be issued.

## Install the server prerequisites

```powershell
# .\Examples\Initialize-ISHServer.ps1
```

The current script install the Oracle ODAC client. At this moment, I can't find a way to make it work without a restart of the server. The script takes care of this automatically.

This step uses the `PrerequisitesSourcePath` for the xISHServer 3rd party dependencies. The file are copies from this folder into the remote server. The required files are explained in [About xISHServer module](About xISHServer module.md) 
The values of `CredentialForCredSSPExpression` and `OSUserCredentialExpression` are an abstraction to the credentials for a user that can establish a session with CredSSP and for the osuser.
Behind the scenes the `Invoke-Expression` is used to execute the specified cmdlet. In my profile scripts I've made sure that cmdlets `New-MyCredential` and `New-InfoShareServiceUserCredential` are always available.

## Seed the server with a Content Manager CD

```powershell
& .\Examples\Copy-ISH12.0.0.CD.ps1
```

This step uses the values in 

```json
  "FTP": {
    "Host": "host"
    "User": "user",
    "Password": "password",
    "ISH1200CDFolder": "path",
    "ISH1200CDFileName": "filename"
  }
```

If you have access to a Content Manager CD then you already know what these values are. At the end an ftp url like `ftp://user:host/path/filename` will be formed.

## Install a deployment

```powershell
& .\Examples\Install-ISH.ps1
```

## Apply code as configuration scripts

This section is the one that is expected to modified as much as possible. 
For this reason, all references here are for showcase purpose only.

I've created a script `Invoke-ISHDeployScript.ps1` that picks up the `Scripts` defined in the json's `ISHDeployment`

```json
"ISHDeployment": [
	{
	  "Suffix": "SQL",
	  "IsOracle": false,
	  "ConnectionString": "",
	  "LucenePort": 9010,
	  "UseRelativePaths": false,
	  "Scripts": [
		"ISHDeploy\\Set-UIFeatures.ps1",
		"ISHDeploy\\Set-ADFSIntegration.ps1"
	  ]
	}
  ]
```

To showcase the potential of ISHDeploy I've crafted a two scripts with a variation. 
Each script works against a target computer and a specific deployment that is generated like this `InfoShare$Suffix`.

- `Set-UIFeatures.ps1` shows a small script that 
  - Enables Content Editor and sets the license.
  - Enables Quality Assurance.
  - Enables Externa Preview for a specific user.
  - Adds a dummy tab to Content Manager Event Monitor.
- `Set-ADFSIntegration.ps1` combines the **ADFS** PowerShell module to
  1. Figure out all values configured on a specific ADFS**
  1. Configure the Content Manager with them 
  1. Extract a script from the deployment that configures ADFS**
  1. Execute the script
 
`Set-ADFSIntegration.ps1` is prime example of how someone can utilize multiple modules to fully automate a manual process.

You can trigger the sequence with 

```powershell
& .\Examples\Invoke-ISHDeployScript.ps1
```

The above scripts are based on executing script blocks on the remote servers. 
This pattern is not very friendly to the concept of code as configuration as described on [code as configuration](https://sarafian.github.io/post/code%20as%20configuration/). 
Although much of the noise is hidden away using the `Invoke-CommandWrap` which is available on [gist](https://gist.github.com/Sarafian/a277cd64468a570dff74682eb929ff3c) for some people it is not good enough. 
For this reason both scripts have a sibling counterpart that uses implicit remoting as described on [import and use module from a remote server](https://sarafian.github.io/post/powershell/Import-Use-Module-Remote-Server/).

- `Set-UIFeatures.ImplicitRemoting.ps1`
- `Set-ADFSIntegration.ImplicitRemoting.ps1`

Both scripts do exactly the same thing but the code is conceptually different. 
You must also watch out because the code executes also differently. 
There are some important aspects of PowerShell remoting that one needs to be aware of. 
Read more about it on [PowerShell remoting caveats](https://sarafian.github.io/post/powershell/powershell-remoting-caveats/) and google.

You can trigger the sequence with 

```powershell
& .\Examples\Invoke-ISHDeployScript.ps1 -UseImplicitRemoting
```

The `Invoke-ISHDeployScript.ps1` converts any script references from `path\filename.ps1` to `path\filename.ImplicitRemoting.ps1` when `-UseImplicitRemoting` parameter is used.

For development purposes, if you need to undo all changes made by these scripts on the deployment then execute

```powershell
& .\Examples\Undo-ISHDeployment.ps1
#or
& .\Examples\Undo-ISHDeployment.ImplicitRemoting.ps1
```

The scripts with implicit remoting use the `Invoke-ImplicitRemoting` cmdlet defined in the repository. 
This is a variation of `Invoke-CommandWrap` and it executes a script block that uses cmdlets from a module that is available on a remote server by first importing implicitly the defined modules. 
It will also do some cleanup. 
The most amazing thing is that you can debug each line of the block!

# Final remarks

- With some minor modifications the entire process can be executed against the local operating system. Start with not defining `ComputerName` in the json file. Since everything executes locally we don't need to configure **Enable the CredSSP authentication for PSSession** but please take notice on the remark. 
- The flow is split into what I considered isolated steps. This repository is a showcase and some steps need to be adjusted accordingly to match production level requirements. 
**Please keep in mind the acknowledgements of the repository**.