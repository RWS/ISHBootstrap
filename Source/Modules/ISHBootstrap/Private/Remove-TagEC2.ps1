<#
.Synopsis
   Remove the tag from EC2 instance
.DESCRIPTION
   With the assumption that the operating system is hosted on AWS EC2, remove the tag from EC2 instance
.EXAMPLE
   Remove-TagEC2 -Name name
#>
function Remove-TagEC2 {
   [CmdletBinding()]
   param (
      [Parameter(Mandatory = $true)]
      [string]$Name
   )

   begin {
   }

   process {
      Write-Debug "Querying the metada endpoint"
      $instanceId = Get-EC2InstanceMetadata -Category InstanceId
      Write-Debug "instanceId=$instanceId"

      Remove-EC2Tag -Resource $instanceId -Tag @{ Key=$Name } -Force
   }

   end {

   }
}
