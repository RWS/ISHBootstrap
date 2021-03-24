<#
.Synopsis
   Get the components from tags
.DESCRIPTION
   Get the components from tags
.EXAMPLE
   Get-ISHComponents
#>
Function Get-ISHComponents {
    [CmdletBinding()]
    param(

    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach($psbp in $PSBoundParameters.GetEnumerator()){Write-Debug "$($psbp.Key)=$($psbp.Value)"}

        $tagNamePrefix="ISHComponent-"
    }

    process {
        Get-Tag | Where-Object {$_.Name.StartsWith("$($tagNamePrefix)")} | ForEach-Object {
            if($_.Name -eq "$($tagNamePrefix)BackgroundTask")
            {
                # This is background task component and we need to extract the role also
                $roles=$_.Value -split ','
                $roles | Select-Object @{Name="Name";Expression={"BackgroundTask"}},@{Name="Role";Expression={$_}}
            }
            else
            {
                $_ | Select-Object @{Name="Name";Expression={$_.Name.Replace($tagNamePrefix,"")}},@{Name="Role";Expression={$null}}
            }
        }

    }

    end {

    }
}