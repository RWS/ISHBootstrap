FROM microsoft/windowsservercore:latest

MAINTAINER Alex Sarafian

ARG ishVersion
ARG accessKey
ARG secretKey
ARG mockConnectionString

ENV ConnectionString _
ENV DBType sqlserver2014
ENV OsUserName InfoShareServiceUser
ENV OsUserPassword Password123
ENV PFXCertificatePath _
ENV PFXCertificatePassword _
ENV HostName _

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ADD . C:/Provision/ISHBootstrap/Source
ADD https://github.com/Microsoft/iis-docker/blob/master/windowsservercore/ServiceMonitor.exe?raw=true /Provision/ServiceMonitor.exe

RUN & C:/Provision/ISHBootstrap/Source/Builders/Default/Install-ISHBootstrapPrerequisites.ps1 -ISHVersion $Env:ishVersion -AWS

RUN $aws=& C:/Provision/ISHBootstrap/Source/Builders/Default/New-ISHBootstrapAWSReferences.ps1 -ISHVersion $Env:ishVersion; \
    & C:/Provision/ISHBootstrap/Source/Bake-ISHFromAWSS3.ps1 -ISHVersion $Env:ishVersion -MockConnectionString $Env:mockConnectionString -BucketName $aws.BucketName -ISHServerFolder $aws.ISHServerFolder -ISHCDFolder $aws.ISHCDFolder -ISHCDFileName $aws.ISHCDFileName -AccessKey $Env:accessKey -SecretKey $Env:secretKey

# This instruction tells the container to listen on port 80. 
EXPOSE 443

HEALTHCHECK CMD [ "powershell", "-File", "./Provision/ISHBootstrap/Source/Docker/ISH.HealthCheck.ps1", "-IncludeMSSQL" ]

CMD ./Provision/ISHBootstrap/Source/Docker/ISH.Cmd.ps1 -ConnectionString $Env:ConnectionString -DBType $Env:DBType -OsUserName $Env:OsUserName -OsUserPassword $Env:OsUserPassword -PFXCertificatePath $Env:PFXCertificatePath -PFXCertificatePassword $Env:PFXCertificatePassword -HostName $Env:HostName -Loop