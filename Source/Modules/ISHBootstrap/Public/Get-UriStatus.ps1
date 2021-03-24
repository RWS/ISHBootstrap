<#
.Synopsis
   Get the HTTP status of URI
.DESCRIPTION
   Get the HTTP status of URI
.EXAMPLE
   Get-UriStatus -Uri uri
.NOTES
   Use this cmdlet to wrap the fact that Invoke-WebRequest breaks and throws too many errors.
#>
Function Get-UriStatus {
    [OutputType([Int])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        try {
            # Invoke-WebRequest throws errors for status codes it doesn't like
            # For the 400 and 500 series we need to get the status code from the exception

            add-type @"
                using System.Net;
                using System.Security.Cryptography.X509Certificates;
                public class TrustAllCertsPolicy : ICertificatePolicy {
                    public bool CheckValidationResult(
                        ServicePoint srvPoint, X509Certificate certificate,
                        WebRequest request, int certificateProblem) {
                            return true;
                        }
                    }
"@
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

            $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -DisableKeepAlive -Headers @{"Cache-Control" = "no-cache" } -MaximumRedirection 0 -ErrorAction SilentlyContinue
            Write-Debug "response.StatusCode=$($response.StatusCode)"
            Write-Verbose "Invoke-WebRequest -Uri $uri returned a valid response"
            $response.StatusCode
        }
        catch {
            # Check if the error is not related to certificate validation
            if (($_.Exception.InnerException) -and ($_.Exception.InnerException -is [System.Security.Authentication.AuthenticationException]) -and ($_.Exception.InnerException.Message -eq "The remote certificate is invalid according to the validation procedure.")) {
                throw
            }
            Write-Debug "_.Exception.Response.StatusCode=$($_.Exception.Response.StatusCode)"
            Write-Verbose "Invoke-WebRequest -Uri $uri returned a valid response after error handling"
            [int]$_.Exception.Response.StatusCode
        }
    }

    end {

    }
}