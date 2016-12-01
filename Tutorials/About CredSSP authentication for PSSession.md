# About CredSSP authentication for PSSession

When through remoting we try to access a kerberos protected asset then by default it fails.
To solve the issue we need to configure windows to allow the creation of CredSSP session.

# Configure the server

1.  add feature `Add-WindowsFeature WinRM-IIS-Ext`
1.  run `Enable-WSManCredSSP -Role server` 
1.  run `winrm quickconfig -transport:https`
1.  Grant permissions to the `NETWORK SERVICE` to the private key of the certificate. To find the assigned certificate run `winrm enumerate winrm/config/listener`
1.  Might be necessary to open a port for the WinRM-HTTPS. Run `netsh advfirewall firewall add rule name="WinRM-HTTPS" dir=in localport=5986 protocol=TCP action=allow`   

Now the server can accept **secure** session requests with **credSSP**

# Configure the client

Create a session like this
```powershell
$computer="SERVER01"
$session=New-PSSession -ComputerName $computer -Credential (Get-Credential) -Authentication CredSSP -UseSSL
```

You will get this error

> New-PSSession : [SERVER01] Connecting to remote server SERVER01 failed with the following error message : The WinRM client cannot process the request. 
> A computer poliand look at the following policy: Computer Configuration -> Administrative Templates -> System -> Credentials Delegation -> Allow Delegating Fresh Credentials.  
> Verify that itarget computer name "myserver.domain.com", the SPN can be one of the following: WSMAN/myserver.domain.com or WSMAN/*.domain.com. For more information, see the about_Remote_T

To enable the feature either follow the steps described in the error or execute this

```powershell
Enable-WSManCredSSP -Role client -DelegateComputer *.domain.com
```

# Test the connection

To test the connection execute 

```powershell
$computer="SERVER01"
try
{
    $session=New-PSSession -ComputerName $Computer -Credential (Get-Credential) -UseSSL -Authentication CredSSP
    Invoke-Command -Session $session -ScriptBlock {Get-ChildItem "\\SERVER02\C$"}
}
finally
{
    if($session)
    {
        Remove-PSSession $session
        $session=$null
    }
}
```