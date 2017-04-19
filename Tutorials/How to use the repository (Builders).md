# How to use the repository (Builders)

The **builders** is a collection of scripts that wrap up the rest of the repository to build artifacts such as:

- Amazon Web Services (AWS) EC2 AMI.
- Docker container image.
- Vagrant boxes

# Examples

## Baking

The following example bakes a **SDL Knowledge Center 2016 SP3 Content Manager** (`$ishVersion="12.0.3"`)

```powershell
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Save-Script -Name Get-Github -Path $env:TEMP -Force
$getGitHubPath=Join-Path $env:TEMP Get-GitHub.ps1
$ishBootstrapPath=(& $getGitHubPath -User Sarafian -Repository ISHBootstrap -Expand).FullName
$buildersPath="$ishBootstrapPath\Source\Builders"

$ishVersion="12.0.3"
$awsISH1203=@{
    BucketName="sct-released"
    ISHServerFolder="InfoShare/12.0/PreRequisites"
    ISHCDFolder="InfoShare/12.0/"
    ISHCDFileName="20170125.CD.InfoShare.12.0.3725.3.Trisoft-DITA-OT.exe"
    AccessKey="accesskey"
    SecretKey="secretkey"
}

& $buildersPath\Default\Install-ISHBootstrapPrerequisites.ps1 -ISHVersion $ishVersion

& $buildersPath\Initialize-ISHImage.ps1 @awsISH1203 -ISHVersion $ishVersion -InformationAction Continue -ErrorAction Stop
```

## Instantiating

The following example picks up a baked artifact and instantiates to a functioning instance

```powershell
#requires -runasadministrator

Set-StrictMode -Version latest

Save-Script -Name Get-Github -Path $env:TEMP -Force
$getGitHubPath=Join-Path $env:TEMP Get-GitHub.ps1
$ishBootstrapPath=(& $getGitHubPath -User Sarafian -Repository ISHBootstrap -Branch import-builders -Expand).FullName
$buildersPath="$ishBootstrapPath\Source\Builders"

$osUserCredentials=New-Object System.Management.Automation.PSCredential("InfoShareServiceUser",(ConvertTo-SecureString "Password123" -AsPlainText -Force))
$instance=@{
    OsUserCredentials=$osUserCredentials
    PFXCertificatePath=$pfxCertificatePath
    PFXCertificatePassword=$pfxCertificatePassword
    HostName="ish.example.com"
}

& $buildersPath\Initialize-ISH.Instance.ps1 @instance -InformationAction Continue -ErrorAction Stop

Remove-Item -Path $PFXCertificatePath -Force
Remove-Item -Path $PFXCertificatePasswordPath -Force
```

# Using with AWS EC2

**To be improved** but in the meanwhile:

**Create AMI**

1. Launch an EC2 from **Windows Server 2016 Base** AMI.
1. Execute the baking example script.
1. Capture the AMI

**Use AMI**

1. Launch an EC2 from the created AMI.
1. Execute the instantiation example script.

# Using with Docker containers

**To be improved** but in the meanwhile:

In the docker file

- Build the image with the baking example script.
- Run the image with the instantiation example script.

# Using with Hyper-V

**To be improved** but in the meanwhile:

1. Prepare a clean Hyper-V instance.
1. Execute the baking example script.
1. Export the VM.
1. Create a new VM from the exported one.
1. Execute the instantiation example script.

The process can be significantly improved by using [Packer](https://www.packer.io) and [Vagrant](vagrantbox.com). `Invoke-DockerBuild.ps1` and `Invoke-PackerBuild.ps1` wrap around the complexity of initializing parameters for packer and docker and create a container, an AMI or a vagrant box depending on the parameter set used.