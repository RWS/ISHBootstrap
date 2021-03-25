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
   Get the recipe metadata from the active execution
.DESCRIPTION
   Get the recipe metadata from the active execution
   This cmdlet has meaningful execution only when executed from within a recipe's script
.EXAMPLE
   Get-RecipeMetadata
#>
function Get-RecipeMetadata
{
    [CmdletBinding()]
    param (

    )

    begin
    {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach($psbp in $PSBoundParameters.GetEnumerator()){Write-Debug "$($psbp.Key)=$($psbp.Value)"}
    }

    process
    {
        if(Test-Path -Path ENV:\ISHBootstrap_Recipe_Type)
        {
            [pscustomobject]@{
                Type=Get-Item -Path ENV:\ISHBootstrap_Recipe_Type|Select-Object -ExpandProperty Value
                Name=Get-Item -Path ENV:\ISHBootstrap_Recipe_Name|Select-Object -ExpandProperty Value
                Version=Get-Item -Path ENV:\ISHBootstrap_Recipe_Version|Select-Object -ExpandProperty Value|ConvertTo-SemVer
            }
        }
        else
        {
            Write-Warning "Recipe Context is not set because either no recipe was set or the cmdlet is invoked ourside of the execution context of Invoke-CodeDeployHook"
        }
    }

    end
    {

    }
}
