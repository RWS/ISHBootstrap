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

param(
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
    [string]$Country=$null
)
Write-Verbose "Installing WinRM-IIS-Ext"
# Add-WindowsFeature WinRM-IIS-Ext | Out-Null breaks on some servers
# Instead this seems to work
Get-WindowsFeature |Where-Object -Property Name -EQ "WinRM-IIS-Ext"|Add-WindowsFeature
Write-Host "WinRM-IIS-Ext feature is ok"

Write-Verbose "Enabling WSManCredSSP role server"
Enable-WSManCredSSP -Role Server -Force | Out-Null
Write-Host "WSManCredSSP role server is ok"

$hostname=[System.Net.Dns]::GetHostEntry([string]$env:computername).HostName
Write-Debug "hostanme=$hostname"
$certificate=Get-ChildItem "Cert:\LocalMachine\My" |Where-Object {$_.Subject -match $hostname -and (Get-CertificateTemplate $_) -eq "WebServer"}
if(-not $certificate)
{
    Write-Verbose "Requesting Web server certificate."
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
    New-DomainSignedCertificate @newDomainSignedCertificateHash | Out-Null
    $certificate=Get-ChildItem "Cert:\LocalMachine\My" |Where-Object {$_.Subject -match $hostname -and (Get-CertificateTemplate $_) -eq "WebServer"}
    Write-Host "Installed new certificate with friendly name $($certificate.FriendlyName)"
}
else
{
    Write-Warning "Found certificate with friendly name $($certificate.FriendlyName)"
}
Write-Verbose "Querying if  winrm has https listener"
$httpsLine= (& winrm enumerate winrm/config/listener) -match "HTTPS"
if(-not $httpsLine)
{
    Write-Verbose "Adding winrm https listener"
    & winrm create winrm/config/Listener?Address=*+Transport=HTTPS  "@{Hostname=""$hostname"";CertificateThumbprint=""$($certificate.Thumbprint)""}"
        # Specify the user, the permissions and the permission type
    $permission = "NETWORK SERVICE","Read,FullControl","Allow"
    $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission;

    $keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\";
    $keyName = $certificate.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName;
    $keyFullPath = Join-Path $keyPath $keyName;

    Write-Verbose "Configuring ACL"
    # Get the current acl of the private key
    # This is the line that fails!
    $acl = Get-Acl -Path $keyFullPath;

    # Add the new ace to the acl of the private key
    $acl.AddAccessRule($accessRule);

    # Write back the new acl
    Set-Acl -Path $keyFullPath -AclObject $acl;
    Write-Host "Configured ACL"

}
Write-verbose "Restarting winrm service"
Get-Service -Name WinRM |Restart-Service | Out-Null
Write-Host "Winrm https listener restarted and ok"

$ruleName="WinRM-HTTPS"
$rulePort=5986
Write-Debug "Querying if firewall port for winrm https is open"
if(-not (Get-NetFirewallRule|Where-Object {($_.DisplayName -eq $ruleName) -and ($_.Direction -eq "Inbound")}))
{
    Write-Verbose "Adding firewall port for winrm https is open"
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Action Allow -Protocol "TCP" -LocalPort $rulePort|Out-Null
}
Write-Host "Winrm https firewall port is ok"
