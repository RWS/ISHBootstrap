<#
.Synopsis
   Serializes and writes any hash to a file that is intended to be a manifest
.DESCRIPTION
   Serializes and writes any hash to a file that is intended to be a manifest
#>
Function Export-ManifestHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Hash,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
    foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

    Function hashToStringLines([hashtable]$hash, [int]$level = 1) {
        #region Explanation and example
        <#
    This is a function produces the lines of a hash render.
    For example

    $hash=@{
        Key="Value"
        SubHash=@{
            Key="Value"
        }
    }

    the hash would be rendered as
@{
    Key="Value"
    SubHash=@{
        Key="Value"
    }
}
#>
        #endregion
        if ($level -eq 1) {
            "@{"
        }
        foreach ($kv in $hash.GetEnumerator()) {
            if ($kv.Value -is [hashtable]) {
                "".PadRight($level * 3) + "$($kv.Key)=@{"
                hashToStringLines ($kv.Value) ($level + 1)
                "".PadRight($level * 3) + "}"
            }
            else {
                "".PadRight($level * 3) + "$($kv.Key)=`"$($kv.Value)`""
            }
        }
        if ($level -eq 1) {
            "}"
        }
    }

    # Write the generated hash lines into a file with new line as separator
    (hashToStringLines $hash) -join [System.Environment]::NewLine | Out-File -FilePath $Path -NoNewline -Force

    Write-Verbose "Saved hash to $Path"
}