<#
.Synopsis
   Set the thumbprint on the IIS Default Website https binding
.DESCRIPTION
   Set the thumbprint on the IIS Default Website https binding
.EXAMPLE
   Set-IISThumbprint -Thumbprint thumbprint
.NOTES
   IIS:\ paths require the WebAdministration module to be loaded
#>
Function Set-IISCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Thumbprint
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach($psbp in $PSBoundParameters.GetEnumerator()){Write-Debug "$($psbp.Key)=$($psbp.Value)"}
    }

    process {
        Get-Item -Path "Cert:\LocalMachine\My\$Thumbprint" | Set-Item -Path "IIS:\SslBindings\0.0.0.0!443"
    }

    end {

    }
}