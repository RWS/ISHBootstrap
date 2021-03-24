<#
.Synopsis
   Create new PSCredential
.DESCRIPTION
   Create new PSCredential from username and non-secure password
.EXAMPLE
   New-PSCredential -Username username -Password password
#>
function New-PSCredential {
   [CmdletBinding()]
   param(
      [Parameter(Mandatory = $true)]
      [string]$Username,
      [Parameter(Mandatory = $true)]
      [string]$Password
   )

   begin {
      Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
      foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
   }

   process {
      Write-Debug "Username=$Username"
      $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
      New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
   }

   end {

   }
}