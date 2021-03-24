<#
.Synopsis
   Starts the web application pools for all web applications: ISHCM, (ISHCS,) ISHSTS and ISHWS
.DESCRIPTION
   Starts the web application pools for all web applications: ISHCM, (ISHCS,) ISHSTS and ISHWS
   This is only for internal purposes and beyond the scope of the component manager
.EXAMPLE
   Start-ISHWeb
.Link
   Stop-ISHWeb
#>
Function Start-ISHWeb {
    [CmdletBinding()]
    param(

    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
    }

    process {

        Get-ISHDeploymentParameters | Where-Object -Property Name -Like "infoshare*webappname" | ForEach-Object {
            $appPoolName = "TrisoftAppPool$($_.Value)"
            Write-Debug "appPoolName=$appPoolName"

            Write-Debug "Starting web app pool $appPoolName"
            Start-WebAppPool -Name $appPoolName
            Write-Verbose "Started web app pool $appPoolName"
        }
    }

    end {

    }
}
