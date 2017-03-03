FROM microsoft/windowsservercore:latest

MAINTAINER Alex Sarafian

ARG accessKey
ARG secretKey
ARG mockConnectionString

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ADD . C:/Provision/ISHBootstrap/Source

RUN & C:/Provision/ISHBootstrap/Source/Bake-ISHFromAWSS3.ps1" -ISHVersion 12.0.3  -MockConnectionString $Env:mockConnectionString -AccessKey $Env:accessKey -SecretKey $Env:secretKey

# This instruction tells the container to listen on port 80. 
EXPOSE 443

CMD powershell 