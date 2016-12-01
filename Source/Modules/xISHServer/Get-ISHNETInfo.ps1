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

function Get-ISHNETInfo
{
    # http://stackoverflow.com/questions/3487265/powershell-script-to-return-versions-of-net-framework-on-a-machine
    Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
    Get-ItemProperty -name Version,Release -EA 0 |
    Where { $_.PSChildName -match '^(?!S)\p{L}'} |
    Select PSChildName, Version, Release, @{
      name="Product"
      expression={
          switch -regex ($_.Release) {
            "378389" { [Version]"4.5" }
            "378675|378758" { [Version]"4.5.1" }
            "379893" { [Version]"4.5.2" }
            "393295|393297" { [Version]"4.6" }
            "394254|394271" { [Version]"4.6.1" }
            "394802|394806" { [Version]"4.6.2" }
            {$_ -gt 394806} { [Version]"Undocumented 4.6.2 or higher, please update script" }
          }
        }
    }
}
