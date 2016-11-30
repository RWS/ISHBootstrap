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

Function Write-Separator {
    param (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.InvocationInfo]$Invocation,
        [Parameter(Mandatory=$true,ParameterSetName="Header")]
        [switch]$Header,
        [Parameter(Mandatory=$true,ParameterSetName="Footer")]
        [switch]$Footer
    )
    $segments=@()
    if($Header)
    {
        $segments+="Begin"
    }
    if($Footer)
    {
        $segments+="End"
    }
    $segments+="Script"
    $line="["+($segments -join ' ')+"]"+" "+$Invocation.MyCommand.Definition
    Write-Host $line -ForegroundColor White -BackgroundColor Black
    if($Footer)
    {
        Write-Host ""
    }
}
