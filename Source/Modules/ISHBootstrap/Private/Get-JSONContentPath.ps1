<#
.Synopsis
   Get the path of the json file
.DESCRIPTION
   Get the path of the json file based on the requested type
.EXAMPLE
   Get-JSONContentPath -Type type
#>
function Get-JSONContentPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    begin {
        Write-Debug "Type=$Type"
        $moduleStagePath = Get-StageFolderPath
        Write-Debug "moduleStagePath=$moduleStagePath"
    }

    process {
        $path = Join-Path -Path $moduleStagePath -ChildPath "$Type.json"
        Write-Verbose "JSON content path is $path"
        $path
    }

    end {

    }
}
