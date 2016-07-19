# Example scripts

The exacmple scripts depend on data indirection. 
I'm using this to test the validity of scripts.
The data is loaded from a JSON file and then retrieved through a cmdlet.

This allows to share the example scripts.

An example JSON file looks like this 

```json
{
  "ComputerName": "SERVER01",
  "ISHVersion": "12.0.0",
  "EnableSecureWinRM": true,
  "ISHServerRepository": "Repository1",
  "PrerequisitesSourcePath": "C:\\inetpubopen\\ISHServer",
  "CredentialForCredSSPExpression":"New-MyCredential",
  "OSUserCredentialExpression":"New-InfoShareServiceUserCredential",
  "PSRepository": [
    {
      "Name": "Repository1",
      "SourceLocation": "SourceLocationUri",
      "InstallationPolicy": "Trusted"
    }  
  ]
}

```

- `ComputerName` is the target computer name. If not set then all script execute locally
- `ISHVersion` is the target content manager version.
- `PSRepository` is an array with `PSRepository` values. Look up `Register-PSRepository` to understand the values. Leave empty to not register any repository.


Here is an example script
```powershell
# Load the file with the target values
& Load-Json.ps1 -JSONFile "ISH1200.server01.example.com.json"

& Initialize-PowerShellGet.ps1
& Initialize-ServerForRemote.ps1
```

# Production

**The examples section is a showcase**. 
Don't use this mechanism in production. 
Instead look in the example scripts and extract and copy the segments to the production scripts.