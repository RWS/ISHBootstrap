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


Function Get-ProgressHash {
    param (
        [Parameter(Mandatory=$true,ParameterSetName="Local")]
        [Parameter(Mandatory=$true,ParameterSetName="Computer")]
        [Parameter(Mandatory=$true,ParameterSetName="Session")]
        $Activity,
        [Parameter(Mandatory=$false,ParameterSetName="Local")]
        [Parameter(Mandatory=$false,ParameterSetName="Computer")]
        [Parameter(Mandatory=$false,ParameterSetName="Session")]
        [int]$Id=$null,
        [Parameter(Mandatory=$false,ParameterSetName="Local")]
        [Parameter(Mandatory=$false,ParameterSetName="Computer")]
        [Parameter(Mandatory=$false,ParameterSetName="Session")]
        [AllowNull()]
        [hashtable]$ParentProgress=$null,
        [Parameter(Mandatory=$true,ParameterSetName="Computer")]
        [AllowNull()]
        $ComputerName,
        [Parameter(Mandatory=$true,ParameterSetName="Session")]
        [AllowNull()]
        [System.Management.Automation.Runspaces.PSSession]$Session,
        [Parameter(Mandatory=$true,ParameterSetName="Invocation")]
        [System.Management.Automation.InvocationInfo]$Invocation
    ) 

    if($PsCmdlet.ParameterSetName -eq "Invocation")
    {
        $Activity=$Invocation.MyCommand.Definition
    }

    switch ($PsCmdlet.ParameterSetName) 
    {
        'Computer' {
                if($ComputerName)
                {
                    $Activity+=" on $ComputerName"
                }
            }
        'Session' {
                if($Session)
                {
                    $Activity+=" on $($Session.ComputerName)"
                }
            }
        Default {}
    }

    $hash=@{
        Activity=$Activity
    }
    if($Id)
    {
        $hash.Id=$Id
    }
    else
    {
        $hash.Id=Get-Random
    }
    
    if($ParentProgress)
    {
        $hash.ParentId=$ParentProgress.Id
    }

    $hash
}
