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

#requires -runasadministrator
#requires -module CertificatePS

param (
    [Parameter(Mandatory=$true)]
    [string]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$CertificateAuthority,
    [Parameter(Mandatory=$false)]
    [string]$OrganizationalUnit=$null,
    [Parameter(Mandatory=$false)]
    [string]$Organization=$null,
    [Parameter(Mandatory=$false)]
    [string]$Locality=$null,
    [Parameter(Mandatory=$false)]
    [string]$State=$null,
    [Parameter(Mandatory=$false)]
    [string]$Country=$null,
    [Parameter(Mandatory=$true)]
    [securestring]$PfxPassword,
    [Parameter(Mandatory=$false)]
    [switch]$MoveChain=$false
)    

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"
. "$cmdletsPaths\Helpers\Get-RandomString.ps1"

$enableWSManScriptBlock={
    Write-Debug "Enabling WSManCredSSP role server"
    Enable-WSManCredSSP -Role Server -Force | Out-Null
    Write-Verbose "Enabled WSManCredSSP role server"
}

$configureWinRMBlock={
    $winRmListeners=& winrm enumerate winrm/config/listener
    $httpsLine= $winRmListeners -match "HTTPS"
    Write-Debug "httpsLine=$httpsLine"
    if(-not $httpsLine)
    {
        $certificate=Get-ChildItem -Path Cert:\LocalMachine\My |Where-Object -Property Thumbprint -EQ $thumbprint
        Write-Debug "Adding winrm https listener"
        & winrm create winrm/config/Listener?Address=*+Transport=HTTPS  "@{Hostname=""$hostname"";CertificateThumbprint=""$($certificate.Thumbprint)""}"
        Write-Verbose "Added winrm https listener"
        
        Write-Debug "Configuring ACL"
        # Specify the user, the permissions and the permission type
        $permission = "NETWORK SERVICE","Read,FullControl","Allow"
        $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission;

        $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\";
        $keyName = $certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName;
        $keyFullPath = Join-Path $keyPath $keyName;

        # Get the current acl of the private key
        # This is the line that fails!
        $acl = Get-Acl -Path $keyFullPath;

        # Add the new ace to the acl of the private key
        $acl.AddAccessRule($accessRule);

        # Write back the new acl
        Set-Acl -Path $keyFullPath -AclObject $acl;
        Write-Verbose "Configured ACL"
    }
    else
    {
        Write-Warning "winrm https listener detected. Skipped"
    }
}

$restartWinRMBlock= {
    Write-Debug "Restarting winrm service"
    Get-Service -Name WinRM |Restart-Service| Out-Null
    while((Get-Service -Name WinRM).Status -ne "Running")
    {
        Start-Sleep -Milliseconds 500
    }
    Write-Verbose "Restarted WINRM service"
}

$openFireWallWinRMBlock= {
    $ruleName="WinRM-HTTPS"
    $rulePort=5986
    Write-Debug "Querying if firewall port for winrm https is open"
    if(-not (Get-NetFirewallRule|Where-Object {($_.DisplayName -eq $ruleName) -and ($_.Direction -eq "Inbound")}))
    {
        Write-Verbose "Adding firewall port for winrm https is open"
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol "TCP" -LocalPort $rulePort|Out-Null
    }
    Write-Host "Winrm https firewall port is ok"
}

try
{
    Write-Progress @scriptProgress -Status "Issuing certificate"
    $hostname=[System.Net.Dns]::GetHostByName($computerName)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
    $newDomainSignedCertificateHash=@{
        Hostname=$hostname
        CertificateAuthority=$CertificateAuthority
    }
    if($OrganizationalUnit)
    {
        $newDomainSignedCertificateHash.OrganizationalUnit=$OrganizationalUnit
    }
    if($Organization)
    {
        $newDomainSignedCertificateHash.Organization=$Organization
    }
    if($Locality)
    {
        $newDomainSignedCertificateHash.Locality=$Locality
    }
    if($State)
    {
        $newDomainSignedCertificateHash.State=$State
    }
    if($Country)
    {
        $newDomainSignedCertificateHash.Country=$Country
    }

    $certificate=New-DomainSignedCertificate @newDomainSignedCertificateHash
    Write-Host "Installed new certificate with friendly name $($certificate.FriendlyName)"
    $thumbprint=$certificate.Thumbprint
    Write-Progress @scriptProgress -Status "Moving certificate to $computerName"
    $certificate|Move-CertificateToRemote -ComputerName $computerName -PfxPassword $PfxPassword -MoveChain:$MoveChain

    $blockName="Enabling WSManCredSSP role server"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $enableWSManScriptBlock -BlockName $blockName

    $blockName="Configuring WINRM CredSSP authentication"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $configureWinRMBlock -BlockName $blockName -UseParameters @("hostname","thumbprint")

    $blockName="Restarting WINRM service"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $restartWinRMBlock -BlockName $blockName

    $blockName="Openning WINRM https listener ports"
    Write-Progress @scriptProgress -Status $blockName
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $openFireWallWinRMBlock -BlockName $blockName
}
catch
{
    Write-Error $_
}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer
