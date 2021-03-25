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
   Get one or more values from a json file
.DESCRIPTION
   Get one or more values from a json file.
.EXAMPLE
   Get-JSON -Type Tag # Gets all tags
.EXAMPLE
   Get-JSON -Type Marker -Name name # Get a specific marker
#>
Function Get-JSON {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Name = $null,
        [Parameter(Mandatory = $true)]
        [string]$Type

    )

    begin {
        $commonJSONParameters = @{ } + $PSBoundParameters
        $null = $commonJSONParameters.Remove("Name")
        Write-Debug "Name=$Name"
        Write-Debug "Type=$Type"
    }

    process {
        Write-Debug "Processing JSON for Type=$Type"
        if ($Name) {
            Write-Debug "Testing if item with Name=$Name exists"
            if (Test-JSON -Name $Name @commonJSONParameters) {
                Write-Debug "Found item with Name=$Name"
                Write-Debug "Getting JSONContent"
                $json = Get-JSONContent @commonJSONParameters
                $value = Invoke-Expression "`$json.'$Name'"
                Write-Verbose "Found item with Name=$Name and Value=$value"
                $value
            }
            else {
                throw "$Type $Name not found"
            }
        }
        else {
            Write-Debug "Getting JSON Content"
            $json = Get-JSONContent @commonJSONParameters
            Write-Debug "Processing JSON Content"
            $json | Get-Member -MemberType NoteProperty | ForEach-Object {
                $hash = [ordered]@{
                    Name  = $_.Name
                    Value = Invoke-Expression "`$json.'$($_.Name)'"
                }
                Write-Verbose "Found item with Name=$($hash.Name) and Value=$($hash.Value)"
                New-Object -TypeName PsObject -Property $Hash
            }
        }
    }

    end {

    }
}
