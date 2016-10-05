# About xISHServer module

The **xISHServer** PowerShell module provides the necessary cmdlets to bootstrap a SDL Knowledge Center Content Manager deployment for the following operating systems:

- Windows Server 2012 R2
- Windows Server 2016
- Windows 10 Pro
- Windows 8.1 Pro (Not validated but allowed)

The module appears with the following names 

- xISHServer.12 that is the module for SDL Knowledge Center 2016 releases
- xISHServer.13 that is for the next major version of SDL Knowledge Center

The differences have to do with the requirements of each release. For example the SDL Knowledge Center 2016 require MSDTC but the next major release doesn't. 
For this some cmdlets are removed. 
Also, there is a difference in the required .NET version

# How to work with the module

The module requires the 3rd party tools to be uploaded to a specific directory. 
To retrieve the directory use `Get-ISHServerFolderPath -UNC` to get a path such as `SERVER01\C$\ProgramData\ISHServer.12\`. 
Copy the required files into this folder before executing the cmdlets.

**Tip**. PowerShell v5 introduces session support for the `Copy-Item`. In this case use `Get-ISHServerFolderPath` to get the absolute local path `c:\ProgramData\ISHServer.12\`

You can acquire the files from the given SDL ftp site or you can download them from the internet if available.

Some of the pre-requisites require to server to restart.

## Required files for xISHServer.12

- MSXML 4.0
  - MSXML.40SP3.msi
- JAVA
  - jdk-8u60-windows-x64.exe
  - jre-8u60-windows-x64.exe
- Java Help
  - javahelp-2_0_05.zip  
- Html Help  
  - htmlhelp.zip
- Microsoft VisualC++ 4.5
  - NETFramework2013_4.5_MicrosoftVisualC++Redistributable_(vcredist_x64).exe
- Oracle ODAC 
  - ODTwithODAC121012.rsp
  - ODTwithODAC121012.zip
- Microsoft VisualC++ 2010 (Required for AntennaHouse)
  - V6-2-M9-Windows_X64_64E.exe.vcredist_x64.exe
  - V6-2-M9-Windows_X64_64E.exe.vcredist_x86.exe
- AntennaHouse
  - V6-2-M9-Windows_X64_64E.exe
  - V6-2-M9-Windows_X64_64E.exe.iss
  - AHFormatter.lic
- Visual Basic Runtime (required only for core variants)
  - vbrun60sp6.exe. Get it from [Service Pack 6 for Visual Basic 6.0: Run-Time Redistribution Pack (vbrun60sp6.exe)](https://www.microsoft.com/en-us/download/details.aspx?id=24417) and then extract.

## Required files for xISHServer.13

- MSXML 4.0
  - MSXML.40SP3.msi
- JAVA
  - jdk-8u60-windows-x64.exe
  - jre-8u60-windows-x64.exe
- Java Help
  - javahelp-2_0_05.zip  
- Html Help  
  - htmlhelp.zip
- Microsoft .NET 4.6.1
  - NETFramework2015_4.6.1.xxxxx_(NDP461-KB3102436-x86-x64-AllOS-ENU).exe. (required only for pre Windows Server 2016 installations).
- Microsoft VisualC++ 4.6
  - NETFramework2015_4.6_MicrosoftVisualC++Redistributable_(vc_redist.x64).exe
- Oracle ODAC 
  - ODTwithODAC121012.rsp
  - ODTwithODAC121012.zip
- Microsoft VisualC++ 2010 (Required for AntennaHouse)
  - V6-2-M9-Windows_X64_64E.exe.vcredist_x64.exe
  - V6-2-M9-Windows_X64_64E.exe.vcredist_x86.exe
- AntennaHouse
  - V6-2-M9-Windows_X64_64E.exe
  - V6-2-M9-Windows_X64_64E.exe.iss
  - AHFormatter.lic
- Visual Basic Runtime (required only for core variants)
  - vbrun60sp6.exe. Get it from [Service Pack 6 for Visual Basic 6.0: Run-Time Redistribution Pack (vbrun60sp6.exe)](https://www.microsoft.com/en-us/download/details.aspx?id=24417) and then extract.
  
# Why is the module not on PowerShell gallery

At this moment of time I don't want to publish the module to gallery yet. 
If you still want to use it then you need to publish it to an internal nuget server and install it from there.

# Why is this not a DSC module?

Because when I started the interal code, I didn't had the time to investigate DSC.
  
  
  
  

