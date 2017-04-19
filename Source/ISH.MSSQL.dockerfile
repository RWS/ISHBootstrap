FROM asarafian/mssql-server-windows-express:2014SP2

MAINTAINER Alex Sarafian

ARG ishVersion
ARG accessKey
ARG secretKey

ENV OsUserName InfoShareServiceUser
ENV OsUserPassword Password123
ENV PFXCertificatePath _
ENV PFXCertificatePassword _
ENV HostName _
ENV sa_password _
ENV ACCEPT_EULA _

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ADD . C:/Provision/ISHBootstrap/Source
ADD https://github.com/Microsoft/iis-docker/blob/master/windowsservercore/ServiceMonitor.exe?raw=true /Provision/ServiceMonitor.exe

RUN & C:/Provision/ISHBootstrap/Source/Builders/Default/Install-ISHBootstrapPrerequisites.ps1 -ISHVersion $Env:ishVersion -AWS

RUN $aws=& C:/Provision/ISHBootstrap/Source/Builders/Default/New-ISHBootstrapAWSReferences.ps1 -ISHVersion $Env:ishVersion; \
    & C:/Provision/ISHBootstrap/Source/Bake-ISHFromAWSS3.ps1 -ISHVersion $Env:ishVersion -BucketName $aws.BucketName -ISHServerFolder $aws.ISHServerFolder -ISHCDFolder $aws.ISHCDFolder -ISHCDFileName $aws.ISHCDFileName -AccessKey $Env:accessKey -SecretKey $Env:secretKey -ErrorAction Stop

# This instruction tells the container to listen on port 80. 
EXPOSE 443

HEALTHCHECK CMD [ "powershell", "-File", "./Provision/ISHBootstrap/Source/Docker/ISH.HealthCheck.ps1", "-IncludeMSSQL" ]

CMD ./Provision/ISHBootstrap/Source/Docker/ISH.Cmd.ps1 -OsUserName $Env:OsUserName -OsUserPassword $Env:OsUserPassword -PFXCertificatePath $Env:PFXCertificatePath -PFXCertificatePassword $Env:PFXCertificatePassword -HostName $Env:HostName -sa_password $env:sa_password -ACCEPT_EULA $env:ACCEPT_EULA -Loop