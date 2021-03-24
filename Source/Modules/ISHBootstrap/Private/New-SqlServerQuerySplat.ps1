#region TODO Invoke-SqlServerQuery@InvokeQuery

<#
.Synopsis
   Create a splat for the InvokeQuery:Invoke-SqlServerQuery connection
.DESCRIPTION
   Create a splat for the InvokeQuery:Invoke-SqlServerQuery connection
.EXAMPLE
   New-SqlServerQuerySplat
#>
function New-SqlServerQuerySplat {
    [OutputType([Collections.Hashtable])]
    [CmdletBinding()]
    param (
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        $connectionString = Get-ISHIntegrationDB | Select-Object -ExpandProperty RawConnectionString

        $splat = @{

        }
        $credentialSplat = @{

        }
        $connectionString -split ';' | ForEach-Object {
            $key = ($_ -split '=')[0]
            $value = ($_ -split '=')[1]
            switch ($key) {
                'Data Source' {
                    $splat.Server = $value
                }
                'Initial Catalog' {
                    $splat.Database = $value
                }
                'User ID' {
                    $credentialSplat.Username = $value
                }
                'Password' {
                    $credentialSplat.Password = $value
                }
            }
        }
        $splat.Credential = New-PSCredential @credentialSplat

        $splat
    }

    end {

    }
}

#endregion