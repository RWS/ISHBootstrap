<#
.Synopsis
   Get the credentials
.DESCRIPTION
   Get the credentials from deployment parameters
.EXAMPLE
   Get-ISHCredential -ServiceUser
.EXAMPLE
   Get-ISHCredential -ServiceAdmin
#>
Function Get-ISHCredential {
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $true, ParameterSetName = "ServiceUser")]
        [switch]$ServiceUser,
        [parameter(Mandatory = $true, ParameterSetName = "ServiceAdmin")]
        [switch]$ServiceAdmin
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $deploymentParameters = Get-ISHDeploymentParameters -ShowPassword
        switch ($PSCmdlet.ParameterSetName) {
            'ServiceUser' {
                New-PSCredential
                -Username ($deploymentParameters | Where-Object -Property Name -Like 'serviceusername').Value
                -Password ($deploymentParameters | Where-Object -Property Name -Like 'servicepassword').Value
            }
            'ServiceAdmin' {
                # TODO: Get actual credential from ISHDeploymentParameters which are not there at this moment.
                if ($deploymentParameters | Where-Object -Property Name -Like 'adminusername') {
                    New-PSCredential
                    -Username ($deploymentParameters | Where-Object -Property Name -Like 'adminusername').Value
                    -Password ($deploymentParameters | Where-Object -Property Name -Like 'adminpassword').Value
                }
                else {
                    New-PSCredential -Username 'admin' -Password 'admin'
                }
            }
        }

    }

    end {

    }
}