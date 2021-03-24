<#
.Synopsis
   Stops the web application pools for all web applications: ISHCM, (ISHCS,) ISHSTS and ISHWS
.DESCRIPTION
   Stops the web application pools for all web applications: ISHCM, (ISHCS,) ISHSTS and ISHWS
   This is only for internal purposes and beyond the scope of the component manager
.EXAMPLE
   Stop-ISHWeb
.Link
   Start-ISHWeb
#>
Function Stop-ISHWeb {
    [CmdletBinding()]
    param(

    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        Write-Debug "RootPath=$RootPath"

    }

    process {

        Get-ISHDeploymentParameters | Where-Object -Property Name -Like "infoshare*webappname" | ForEach-Object {
            $appPoolName = "TrisoftAppPool$($_.Value)"
            Write-Debug "appPoolName=$appPoolName"

            Write-Debug "Stopping web app pool $appPoolName"
            Stop-WebAppPool -Name $appPoolName
            Write-Verbose "Stopped web app pool $appPoolName"
        }

    }

    end {

    }
}
