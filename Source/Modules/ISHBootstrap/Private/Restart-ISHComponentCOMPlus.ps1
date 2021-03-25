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

#region TODO COMPLUS-Occasional-Unpredictable-Fail

<#
.Synopsis
   Test if ASP is working and if not kill dllhost.exe
.DESCRIPTION
   Test if ASP is working and if not kill dllhost.exe
.EXAMPLE
   Restart-ISHComponentCOMPlus
#>
Function Restart-ISHComponentCOMPlus {
    [CmdletBinding()]
    param(
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
    }

    process {

        $deployment = Get-ISHDeployment
        $ishCMUrl = "https://$($deployment.AccessHostName)/$($deployment.WebAppNameCM)/"
        $ishCMTestCDevaUrl = $ishCMUrl + "ClientConfig/TestCDeva.asp"
        $ishCMTestCDevaPath = Join-Path -Path $deployment.WebPath -ChildPath "Author\ASP\ClientConfig\TestCDeva.asp"
        $ishCMTestCDevaContent = '<% Set oDeva = Server.CreateObject("ISAuthor.CDeva") %>'

        Write-Debug "ishCMTestCDevaUrl=$ishCMTestCDevaUrl"
        Write-Debug "ishCMTestCDevaPath=$ishCMTestCDevaPath"
        Write-Debug "ishCMTestCDevaContent=$ishCMTestCDevaContent"

        try {
            Write-Debug "Creating $ishCMTestCDevaPath"
            Set-Content -Path $ishCMTestCDevaPath -Value $ishCMTestCDevaContent -NoNewline
            Write-Verbose "Created $ishCMTestCDevaPath"

            $i = 1
            $status = Get-UriStatus -Uri $ishCMTestCDevaUrl
            Write-Debug "status[$i]=$status"
            while (($status -eq 500) -and ($i -lt 5)) {
                Write-Warning "COMPlus failed. Trying to force a restart"
                Get-Process -Name dllhost -IncludeUserName -ErrorAction SilentlyContinue | ForEach-Object {
                    Write-Debug "Stopping process $($_.ProcessName) with id $($_.Id) for user $($_.UserName)"
                    $_ | Stop-Process -Force
                }
                Start-Sleep -Milliseconds 500
                $i++
                $status = Get-UriStatus -Uri $ishCMTestCDevaUrl
                Write-Debug "status[$i]=$status"
            }

            if ($status -eq 500) {
                throw "COMPlus is started but not functioning well"
            }
            Write-Verbose "COMPlus is started and verified"
        }
        finally {
            Write-Debug "Removing $ishCMTestCDevaPath"
            Remove-Item -Path $ishCMTestCDevaPath -ErrorAction SilentlyContinue
            Write-Verbose "Removed $ishCMTestCDevaPath"
        }
    }

    end {

    }
}

#endregion
