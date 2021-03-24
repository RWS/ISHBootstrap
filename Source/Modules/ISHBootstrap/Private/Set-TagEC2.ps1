<#
.Synopsis
   Set the tag for EC2 instance
.DESCRIPTION
   With the assumption that the operating system is hosted on AWS EC2, set the tag for EC2 instance
.EXAMPLE
   Set-TagEC2 -Name name
.EXAMPLE
   Set-TagEC2 -Name name -Value value
#>
function Set-TagEC2 {
   [CmdletBinding()]
   param (
      [Parameter(Mandatory = $true)]
      [string]$Name,
      [Parameter(Mandatory = $false)]
      $Value = $null
   )

   begin {
   }

   process {
      Write-Debug "Querying the metada endpoint"
      $instanceId = Get-EC2InstanceMetadata -Category InstanceId
      Write-Debug "instanceId=$instanceId"

      $tag = New-Object Amazon.EC2.Model.Tag
      $tag.Key = $Name
      $tag.Value = $Value
      Write-Debug "Tag=$tag"

      New-EC2Tag -Resource $instanceId -Tag $tag
   }

   end {

   }
}
