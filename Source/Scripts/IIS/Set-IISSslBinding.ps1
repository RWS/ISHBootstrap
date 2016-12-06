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

param (
    [Parameter(Mandatory=$false)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$false)]
    [string]$Thumbprint=$null
)
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

try
{
    $block={
        if(-not $Thumbprint)
        {
            $hostname=[System.Net.Dns]::GetHostEntry([string]$env:computername).HostName
            Write-Debug "hostname=$hostname"
            $certificate=Get-ChildItem "Cert:\LocalMachine\My" |Where-Object {$_.Subject -match $hostname -and (Get-CertificateTemplate $_) -eq "WebServer"}
            Write-Verbose "Using certificate with friendly name $($certificate.Subject)"
            $Thumbprint=$certificate.Thumbprint
        }

        Import-Module WebAdministration -ErrorAction Stop

        Write-Debug "Querying if IIS has https binding"
        $webBinding=Get-WebBinding 'Default Web Site' -Protocol "https"
        if(-not $webBinding)
        {
            Write-Debug "Creating IIS https binding"
            New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https|Out-Null
            Write-Verbose "Created IIS https binding"
        }

        Write-Verbose "Assigning certificate with $Thumbprint to SSL"
        Push-Location "IIS:\SslBindings" -StackName "IIS"
        $thumbprintItem=Get-Item cert:\LocalMachine\MY\$Thumbprint
        if(Test-Path 0.0.0.0!443)
        {
            Remove-Item 0.0.0.0!443 -Force
            Write-Verbose "Removed 0.0.0.0!443"
        }
        $thumbprintItem | New-Item 0.0.0.0!443 |Out-Null
        Pop-Location -StackName "IIS"
        Write-Host "Assigned certificate with $Thumbprint to SSL"
    }
    $blockName="Initialize IIS Binding"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -BlockName $blockName -ScriptBlock $block -UseParameters @("Thumbprint")
}

finally
{
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
