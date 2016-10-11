param (
    [Parameter(Mandatory=$false)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null
)
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

try
{
    $block={
        Import-Module WebAdministration -ErrorAction Stop

        Write-Verbose "Checing if IIS has https binding"
        $webBinding=Get-WebBinding 'Default Web Site' -Protocol "https"
        if(-not $webBinding)
        {
            Write-Verbose "Creating IIS https binding"
            New-WebBinding -Name "Default Web Site" -IP "*" -Port 443 -Protocol https|Out-Null
            Write-Verbose "Created IIS https binding"
            $hostname=[System.Net.Dns]::GetHostEntry([string]$env:computername).HostName
            Write-Debug "hostname=$hostname"
            $certificate=Get-ChildItem "Cert:\LocalMachine\My" |Where-Object {$_.Subject -match $hostname -and (Get-CertificateTemplate $_) -eq "WebServer"}
            Write-Verbose "Using certificate with friendly name $($certificate.Subject)"
            $sslThumbprint=$certificate.Thumbprint
            Write-Verbose "Assigning certificate with $sslThumbprint to SSL"
            Push-Location "IIS:\SslBindings" -StackName "IIS"
            get-item cert:\LocalMachine\MY\$sslThumbprint | New-Item 0.0.0.0!443 |Out-Null
            Pop-Location -StackName "IIS"
            Write-Host "Assigned certificate with $sslThumbprint to SSL"
        }
        else
        {
            Write-Warning "IIS has already an https binding"
        }
    }
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -BlockName "Initialize IIS Binding" -ScriptBlock $block
}

finally
{
}

Write-Separator -Invocation $MyInvocation -Footer