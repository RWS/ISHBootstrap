<#
.Synopsis
   Wait for the ISH Web Components to become ready
.DESCRIPTION
   Wait for the ISH Web Components to become ready
.EXAMPLE
   Wait-ISHWeb
.Link
   Start-ISHWeb
#>
Function Wait-ISHWeb {
    [CmdletBinding()]
    param(

    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
    }

    process {
        $deployment = Get-ISHDeployment
        $urisToWaitFor = @(
            @{
                Uri    = "https://localhost/"
                Status = 200
            }
            @{
                Uri    = "https://localhost/$($deployment.WebAppNameCM)/"
                Status = 302
            }
            @{
                Uri    = "https://localhost/$($deployment.WebAppNameWS)/ConnectionConfiguration.xml"
                Status = 200
            }
            @{
                Uri    = "https://localhost/$($deployment.WebAppNameWS)/Application25.asmx"
                Status = 200
            }
            @{
                Uri    = "https://localhost/$($deployment.WebAppNameWS)/Wcf/API25/Application.svc"
                Status = 200
            }
            @{
                Uri    = "https://localhost/$($deployment.WebAppNameSTS)/"
                Status = 200
            }
        )

        if ($deployment.WebAppNameCS) {
            $urisToWaitFor += @(
                @{
                    Uri    = "https://localhost/$($deployment.WebAppNameCS)/"
                    Status = 302
                }
            )
        }
        $urisToWaitFor | ForEach-Object {
            Write-Verbose "Waiting for $($_.Uri) to respond with status $($_.Status)."
            $splat = $_
            Wait-UriStatus @splat -MilliSeconds 500
        }
    }

    end {

    }
}
