<#
# Copyright (c) 2021 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#>

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
