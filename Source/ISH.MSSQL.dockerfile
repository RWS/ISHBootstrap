FROM asarafian/mssql-server-windows-express:2014SP2

MAINTAINER Alex Sarafian

ARG accessKey
ARG secretKey

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ADD . C:/Provision/ISHBootstrap/Source

RUN & C:/Provision/ISHBootstrap/Source/Bake-ISHFromAWSS3.ps1" -ISHVersion 12.0.3  -AccessKey $Env:accessKey -SecretKey $Env:secretKey

# This instruction tells the container to listen on port 80. 
EXPOSE 443

CMD powershell 