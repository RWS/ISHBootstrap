<#
.Synopsis
    Test if the system is Run on EC2
.DESCRIPTION
    Test if the system is Run on EC2
.EXAMPLE
    Test-RunOnEC2
#>
function Test-RunOnEC2 {
    [OutputType([Boolean])]
    [CmdletBinding()]
    param (
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        <#  Conditions of being on Run on EC2
            AWSPowerShell module is installed
            EC2 metadata is reachable
        #>
        $isAWSToolInstalled = $null -ne (Get-Module -Name AWSPowerShell)
        Write-Debug "isAWSToolInstalled=$isAWSToolInstalled"

        if ($isAWSToolInstalled) {
            $ec2MetadataPointReachable = $null -ne (Get-EC2InstanceMetadata -Category AmiId)

            Write-Debug "ec2MetadataPointReachable=$ec2MetadataPointReachable"

            if ($ec2MetadataPointReachable) {
                if (Get-TagEC2 | Where-Object -Property Name -EQ 'ISHStackConfiguration') {
                    return $true
                }
            }
        }
        return $false
    }

    end {

    }
}
