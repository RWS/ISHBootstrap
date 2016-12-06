<#
# Copyright (c) 2014 All Rights Reserved by the SDL Group.
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

Function Get-ISHBootstrapperContextValue
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $ValuePath,
        [Parameter(Mandatory=$false,ParameterSetName="Default")]
        $DefaultValue=$null,
        [Parameter(Mandatory=$true,ParameterSetName="Expression")]
        [switch]$Invoke
    ) 
    $variableName="__ISHBootstrapper_Data__"

    $data = Get-Variable -Name $variableName -Scope Global -ValueOnly

    $value = Invoke-Expression "`$data.$ValuePath";
    if ($value -eq $null)
    {
        if($PSCommandPath.ContainsKey('DefaultValue'))
        {
            $value=$DefaultValue
        }
        elseif($PSCommandPath.ContainsKey('Invoke'))
        {
        }
        else
        {
            Write-Warning "$ValuePath path does not exist and DefaultValue is not specified"
        }
    }
    else
    {
        if($Invoke)
        {
            $value=Invoke-Expression $value
        }
    }
    $value
}
