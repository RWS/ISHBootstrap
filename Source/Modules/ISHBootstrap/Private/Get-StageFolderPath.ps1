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
   Get the path of the module's folder
.DESCRIPTION
   Get the path of the module's folder
.EXAMPLE
   Get-StageFolderPath
.EXAMPLE
   Get-StageFolderPath -BackupName 'the name of the backup'
#>
function Get-StageFolderPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$BackupName
    )

    begin {

    }

    process {
        #region https://gist.github.com/Sarafian/24177f31e729ea8d64a887e8d34d7ea5
        function Test-PesterInvocation {
            $commandStack = Get-PSCallStack | Select-Object -ExpandProperty Command

            # Fix for Test-ISHLogin.ps1 when executed using local tags. Typically when executing in a non-AWS/EC2 environment like Vagrant/Hyper-V
            #($commandStack -contains "Invoke-Pester") -or ($commandStack -contains "Describe")
            (($commandStack -contains "Invoke-Pester") -and (-not($commandStack -contains "Test-ISHLogin.ps1"))) -or (($commandStack -contains "Describe") -and (-not($commandStack -contains "Test-ISHLogin.ps1")))
        }
        #endregion

        if (Test-PesterInvocation) {
            Write-Verbose "Pester detected"
            $moduleName = "ISHBootstrap.Pester"
        }
        else {
            $moduleName = $($MyInvocation.MyCommand.Module)
        }
        Write-Debug "moduleName=$moduleName"

        $path = Join-Path $env:ProgramData $moduleName

        if ($BackupName) {
            $path = Join-Path -Path $path -ChildPath "Backup"
            $path = Join-Path -Path $path -ChildPath $BackupName
            if (-not(Test-Path -Path $path)) {
                $null = New-Item -Path $path -ItemType Directory
            }
        }
        Write-Verbose "Module path is $path"
        $path
    }

    end {

    }
}
