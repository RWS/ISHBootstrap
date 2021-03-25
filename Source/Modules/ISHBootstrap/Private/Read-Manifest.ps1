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
    Read the manifest
.DESCRIPTION
    Read the manifest of a recipe or hotfix

    Example manifest file

    @{
        Type="ISHRecipe"

        Publish=@{
            Name=""
            Version=""
            Date=""
            Engine=""
        }

        Name=""
        Version=""
        Author="1"
        CompanyName="2"
        Copyright="3"
        Description="4"

        Prerequisite=@{
            Version=@{
                Major="5"
                Minor="6"
                Build="7"
                Revision="7"
            }
        }


        Scripts=@{
            PreRequisite="10"

            Stop=@{
                BeforeCore="21"
                AfterCore="22"
            }

            Execute="30"

            DatabaseUpgrade=@{
                BeforeCore="41"
                AfterCore="42"
            }

            DatabaseUpdate=@{
                BeforeCore="51"
                AfterCore="52"
            }

            Start=@{
                BeforeCore="61"
                AfterCore="62"
            }

            Validate="70"
        }
    }
.EXAMPLE
    Read-Manifest -Path path
#>
Function Read-Manifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    begin {
        Write-Debug "Path=$Path"
        $manifestPath = Split-Path $Path -Parent
        Write-Debug "manifestPath=$manifestPath"

        $manifestItem = Get-Item -Path $Path
        $manifestContent = Get-Content -Path $Path -Raw
        $manifestHash = Invoke-Expression -Command $manifestContent

        function GetScriptPathForEvent([string]$KeyPath) {
            Write-Debug "KeyPath=$KeyPath"
            $segments = $KeyPath -split '\.'
            $containsPath = $true
            $tempValue = $manifestHash
            for ($i = 0; $i -lt $segments.Length; $i++) {
                if (-not ($tempValue.ContainsKey($segments[$i]))) {
                    $containsPath = $false
                    break
                }
                $tempValue = $tempValue["$($segments[$i])"]
            }

            Write-Debug "containsPath=$containsPath"
            if ($containsPath) {
                Join-Path -Path $manifestPath -ChildPath (Invoke-Expression "`$manifestHash.$($KeyPath)")
            }
            else {
                $null
            }
        }

        function GetVersion([string]$KeyPath) {
            Write-Debug "KeyPath=$KeyPath"
            $segments = $KeyPath -split '\.'
            $containsPath = $true
            $tempValue = $manifestHash
            for ($i = 0; $i -lt $segments.Length; $i++) {
                if (-not ($tempValue.ContainsKey($segments[$i]))) {
                    $containsPath = $false
                    break
                }
                $tempValue = $tempValue["$($segments[$i])"]
            }

            Write-Debug "containsPath=$containsPath"
            if ($containsPath) {
                Invoke-Expression "`$manifestHash.$($KeyPath)"
            }
            else {
                $null
            }
        }
    }

    process {
        Write-Debug "Testing validity for $Path"
        if (-not (Test-Manifest -Path $Path)) {
            throw "Unknown manifest structure"
        }
        $hash = @{
            Type                          = $manifestHash.Type
            Author                        = $manifestHash["Author"]
            CompanyName                   = $manifestHash["CompanyName"]
            Copyright                     = $manifestHash["Copyright"]
            Description                   = $manifestHash["Description"]

            Name                          = $manifestHash["Name"]
            Version                       = $manifestHash["Version"]
            Publish                       = $manifestHash["Publish"]

            PrerequisiteMajor             = GetVersion("PreRequisite.Version.Major")
            PrerequisiteMinor             = GetVersion("PreRequisite.Version.Minor")
            PrerequisiteBuild             = GetVersion("PreRequisite.Version.Build")
            PrerequisiteRevision          = GetVersion("PreRequisite.Version.Revision")

            PreRequisitePath              = GetScriptPathForEvent("Scripts.PreRequisite")
            StopBeforeCorePath            = GetScriptPathForEvent("Scripts.Stop.BeforeCore")
            StopAfterCorePath             = GetScriptPathForEvent("Scripts.Stop.AfterCore")
            ExecutePath                   = GetScriptPathForEvent("Scripts.Execute")
            DatabaseUpgradeBeforeCorePath = GetScriptPathForEvent("Scripts.DatabaseUpgrade.BeforeCore")
            DatabaseUpgradeAfterCorePath  = GetScriptPathForEvent("Scripts.DatabaseUpgrade.AfterCore")
            DatabaseUpdateBeforeCorePath  = GetScriptPathForEvent("Scripts.DatabaseUpdate.BeforeCore")
            DatabaseUpdateAfterCorePath   = GetScriptPathForEvent("Scripts.DatabaseUpdate.AfterCore")
            StartBeforeCorePath           = GetScriptPathForEvent("Scripts.Start.BeforeCore")
            StartAfterCorePath            = GetScriptPathForEvent("Scripts.Start.AfterCore")
            ValidatePath                  = GetScriptPathForEvent("Scripts.Validate")

            FileName                      = $manifestItem.Name
            FilePath                      = $manifestItem.FullName
        }
        $hash.Keys | ForEach-Object {
            Write-Debug "hash.key=$($_) hash.Value=$($hash[$_])"
        }

        New-Object -TypeName PSObject -Property $hash
    }

    end {

    }
}
