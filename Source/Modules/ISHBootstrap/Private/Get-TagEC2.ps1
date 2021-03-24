<#
.Synopsis
   Get the tags configured on the current EC2 instance
.DESCRIPTION
   With the assumption that the operating system is hosted on AWS EC2, get the tags configured on the EC2 instance
.EXAMPLE
   Get-TagEC2
#>
function Get-TagEC2 {
    [CmdletBinding()]
    param (
    )

    begin {
    }

    process {
        Write-Debug "Querying the metada endpoint"
        $instanceId = Get-EC2InstanceMetadata -Category InstanceId
        Write-Debug "instanceId=$instanceId"
        $tag = Get-EC2Tag -Filter @{Name = "resource-id";Value=$instanceId} | Select-Object @{Name = "Name"; Expression = { $_.Key } }, Value

        $tag
    }

    end {
    }
}
