# How to use the repository (Builders)

The **builders** is a collection of scripts that wrap up the rest of the repository to build artifacts such as:

- Amazon Web Services (AWS) EC2 AMI.
- Docker container image.
- Vagrant boxes

# Examples

## Baking

The following example bakes a **SDL Knowledge Center 2018 Content Manager** (`$ishVersion="13.0.0"`)

```powershell
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
Save-Script -Name Get-Github -Path $env:TEMP -Force
$getGitHubPath=Join-Path $env:TEMP Get-GitHub.ps1
$ishBootstrapPath=(& $getGitHubPath -User sdl -Repository ISHBootstrap -Expand).FullName
$buildersPath="$ishBootstrapPath\Source\Builders"

$ishVersion="13.0.0"
$awsISH1300=@{
    BucketName="sct-released"
    ISHServerFolder="InfoShare/13.0/PreRequisites"
    ISHCDFolder="InfoShare/13.0/"
    ISHCDFileName="20171110.CD.InfoShare.13.0.3510.0.Trisoft-DITA-OT.exe"
    AccessKey="accesskey"
    SecretKey="secretkey"
}

& $buildersPath\Default\Install-ISHBootstrapPrerequisites.ps1 -ISHVersion $ishVersion

& $buildersPath\Initialize-ISHImage.ps1 @awsISH1300 -ISHVersion $ishVersion -InformationAction Continue -ErrorAction Stop
```

## Instantiating

The following example picks up a baked artifact and instantiates to a functioning instance

```powershell
#requires -runasadministrator

Set-StrictMode -Version latest

Save-Script -Name Get-Github -Path $env:TEMP -Force
$getGitHubPath=Join-Path $env:TEMP Get-GitHub.ps1
$ishBootstrapPath=(& $getGitHubPath -User sdl -Repository ISHBootstrap -Branch import-builders -Expand).FullName
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

# Using with Amazon Web Services

## Building

Use the `Invoke-PackerBuild.ps1` to start building an AMI. 

```powershell
$hash=@{
    ISHVersion="13.0.0"
    IAMInstanceProfile="IAMInstanceProfile"
    Region="eu-west-1"
    AccessKey="AccessKey"
    SecretKey="SecretKey"
    # Optional
    MockConnectionString="MockConnectionString"
}

& .\Invoke-PackerBuild.ps1 @hash
```

When the `MockConnectionString` is not specified, then the root AMI image is a Windows Server 2012 R2 with SQL Server 2014 SP2 Express. The AMI then contains an internal database than can be used when creating new Content Manager EC2 instances

## Instantiating 

As part of the `userdata` or **CodeDeploy** packages, to configure the EC2 execute the `Initialize-ISH.Instance.ps1` as discussed previously.

# Using with Docker containers

**Notice** that SDL Knowledge Center doesn't support the official container technology. This section is created mostly as a fun hobby and to explore what is necessary to for the product to become container friendly. Therefore not containers are published nor available online.

## Building containers

When building the container, you need to specify the `ISHVersion` and amazon authorization for the S3 bucket that holds the ISHBootstrap dependencies. When building the image, there are two options depending on whether a mock connection string for a SQL Server 2014 SP2 ISH database is provided. When not provided, the container will derive from `asarafian/mssql-server-windows-express:2014SP2` and include a database.

The following example builds a **SDL Knowledge Center 2018 Content Manager** (`$ishVersion="13.0.0"`) with embedded SQL Server 2014 SP2. The image name is `asarafian/ishmssql` with tag `13.0.0`.

```powershell

# Build container with internal SQL Server 2016
$hash=@{
    ISHVersion="13.0.0"
    AccessKey="accesskey"
    SecretKey="secretkey"
}

& .\Invoke-DockerBuild.ps1 @hash

```

The following example builds a **SDL Knowledge Center 2018 Content Manager** (`$ishVersion="13.0.0"`) using an external database with connection string `connectionstring`. The image name is `asarafian/ish` with tag `13.0.0`.

```powershell

# Build container with internal SQL Server 2014 SP2
$hash=@{
    ISHVersion="13.0.0"
    AccessKey="accesskey"
    SecretKey="secretkey"
    MockConnectionString="connectionstring"
}

& .\Invoke-DockerBuild.ps1 @hash

```

## Running containers

When running a container we need to provide the following information

| Data | Image | Required | Remarks |
| ---- | ----- | -------- | ------- |
| Certificate | asarafian/ishmssql:12.0.3 | Yes | | 
| Certificate | asarafian/ish:12.0.3 | Yes | | 
| Hostname | asarafian/ishmssql:12.0.3 | No | Will use the certificate's subject name when available. Required when using wild-card certificates |
| Hostname | asarafian/ish:12.0.3 | No | Will use the certificate's subject name when available. Required when using wild-card certificates |
| Credentials | asarafian/ishmssql:12.0.3 | No | Default in the docker file |
| Credentials | asarafian/ish:12.0.3 | No | Default in the docker file |
| Credentials | asarafian/ish:12.0.3 | No | Default in the docker file |
| ACCEPT_EULA | asarafian/ishmssql:12.0.3 | Yes | |
| ACCEPT_EULA | asarafian/ish:12.0.3 | No | |
| Database | asarafian/ish:12.0.3 | Yes | |

The following runs a **SDL Knowledge Center 2016 SP3 Content Manager** (`asarafian/ishmssql:12.0.3`) container with the embedded database

```text
docker run -d -e PFXCertificatePath="PFXCertificatePath" -e PFXCertificatePassword="PFXCertificatePassword" -e HostName="ish.example.com" -e ACCEPT_EULA=Y asarafian/ishmssql:12.0.3
```
The following runs a **SDL Knowledge Center 2016 SP3 Content Manager** (`asarafian/ish:12.0.3`) container

```text
docker run -d -e PFXCertificatePath="PFXCertificatePath" -e PFXCertificatePassword="PFXCertificatePassword" -e HostName="ish.example.com" -e ConnectionString="connectionstring" -e ACCEPT_EULA=Y asarafian/ish:12.0.3
```

The `PFXCertificatePath` has to be a `.pfx` file available on the container's file system, so it's necessary to mount a volume before that. 

The containers are very basic but the provide a very good starting point. Further specialization is required to create containers for specific roles and for specific values. This will accelerate the duration of the `docker run` command.

When the container starts, specific message prefixed with `[DockerHost]` are emitted. To track when the container is ready and the endpoints are available look for `[DockerHost]Container ready` using `docker logs` command.

# Using with Hyper-V

## Building

Use the `Invoke-PackerBuild.ps1` to start building a Vagrant box. 

```powershell
$hash=@{
    ISHVersion="13.0.0"
    IAMInstanceProfile="IAMInstanceProfile"
    Region="eu-west-1"
    AccessKey="AccessKey"
    SecretKey="SecretKey"
    MockConnectionString="MockConnectionString"
    ISOUrl="ISOUrl"
}

& .\Invoke-PackerBuild.ps1 @hash
```

Add the output vagrant box to your environment

## Instantiating 

Within the provisioning section of the Vagrant file, make sure the `Initialize-ISH.Instance.ps1` is executed as discussed previously.