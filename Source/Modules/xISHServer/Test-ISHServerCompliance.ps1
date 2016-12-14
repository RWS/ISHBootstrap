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

function Test-ISHServerCompliance
{
    $osInfo=Get-ISHOSInfo
    if($osInfo.IsServer)
    {
        $isSupported=$osInfo.Version -in '2016','2012 R2'
    }
    else
    {
        $isSupported=$osInfo.Version -in '10','8.1'
        if($osInfo.Version -eq '8.1')
        {
            Write-Warning "Detected not verified operating system $($osInfo.Caption)."
        }
    }
    if(-not $isSupported)
    {
        Write-Warning "Detected not supported operating system $($osInfo.Caption). Do not proceed."
    }
    $isSupported
}
