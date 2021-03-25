<#
# Copyright (c) 2021 All Rights Reserved by the SDL Group.
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
   Upgrade the database
.DESCRIPTION
   Invokes the DBUpgradeTool.exe if the DatabaseUpgrade component is configured on the system
.EXAMPLE
   Update-ISHDB
#>
Function Update-ISHDB {
    [CmdletBinding()]
    param(
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {
        if (Test-ISHComponent -Name DatabaseUpgrade) {
            Invoke-ISHDBUpgradeTool -Upgrade
        }
        else {
            Write-Warning "Skipping. DatabaseUpgrade component not found"
        }
    }

    end {

    }
}
