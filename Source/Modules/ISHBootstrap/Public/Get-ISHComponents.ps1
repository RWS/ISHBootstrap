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
