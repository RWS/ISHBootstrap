<#
.Synopsis
   Get the item of the ISH input parameters file
.DESCRIPTION
   Get the item of the ISH input parameters file
.EXAMPLE
   Get-ISHInputParametersItem
#>
function Get-ISHInputParametersItem {
   [CmdletBinding()]
   param (
   )

   begin {
   }

   process {
      $deployment = Get-ISHDeployment
      Write-Debug "deployment.Name=$($deployment.Name)"
      $regPath = "HKLM:\SOFTWARE\WOW6432Node\Trisoft\InstallTool\InfoShare\$($deployment.Name)"
      Write-Debug "Querying registrigy for regPath=$regPath"
      $folderName = Get-ItemProperty  -Path $regPath -Name Current | Select-Object -ExpandProperty Current
      Write-Debug "folderName=$folderName"

      $item = Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath "Trisoft\InstallTool\InfoShare\$folderName\inputparameters.xml" | Get-Item
      Write-Verbose "item.Path=$($item.FullName)"
      $item
   }

   end {

   }
}
