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
   Get the key
.DESCRIPTION
   Gets the key from tags
.EXAMPLE
   Get-Key -ProjectStage
.EXAMPLE
   Get-Key -ISH
.EXAMPLE
   Get-Key -Custom
#>
Function Get-Key {
    [OutputType([String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "DebugReroute")]
        [switch]$DebugReroute,
        [Parameter(Mandatory = $true, ParameterSetName = "Project+Stage")]
        [switch]$ProjectStage,
        [Parameter(Mandatory = $true, ParameterSetName = "ISH")]
        [switch]$ISH,
        [Parameter(Mandatory = $true, ParameterSetName = "Custom")]
        [switch]$Custom
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $codeVersion = Get-ISHTag -Name "CodeVersion"
        Write-Debug "codeVersion=$codeVersion"
        if ($PSCmdlet.ParameterSetName -ne "DebugReroute") {
            $project = Get-ISHTag -Name "Project"
            $stage = Get-ISHTag -Name "Stage"
            Write-Debug "project=$project"
            Write-Debug "stage=$stage"
        }
    }

    process {

        if ($PSCmdlet.ParameterSetName -eq "DebugReroute") {
            if ($codeVersion -like "debug-*") {
                "$codeVersion/Debug"
            }
            else {
                throw "DebugReroute operations not allowed for codeversion $codeVersion"
            }
        }
        else {
            if ($codeVersion -like "debug-*") {
                $debugCodeVersion = Get-DebugReroute @PSBoundParameters
                if ($debugCodeVersion) {
                    Write-Warning "[DEBUG]Rerouting $codeVersion to $debugCodeVersion"
                    $codeVersion = $debugCodeVersion
                }
            }
            switch ($PSCmdlet.ParameterSetName) {
                'Project+Stage' {
                    "$codeVersion/Project/$project/$stage"
                }
                'ISH' {
                    "$codeVersion/Project/$project/$stage/ISH"
                }
                'Custom' {
                    "$codeVersion/Project/$project/$stage/Custom"
                }
            }
        }
    }

    end {

    }
}
