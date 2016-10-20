param (
    [Parameter(Mandatory=$false)]
    [string]$Computer=$null,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [ValidateSet("12","13")]
    [string]$ISHServerVersion,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [string]$FTPHost,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [pscredential]$FTPCredential,
    [Parameter(Mandatory=$true,ParameterSetName="From FTP")]
    [string]$FTPPath,
    [Parameter(Mandatory=$true,ParameterSetName="From File")]
    [string]$FilePath
)    
$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

if($Computer)
{
    . $cmdletsPaths\Helpers\Add-ModuleFromRemote.ps1
    . $cmdletsPaths\Helpers\Remove-ModuleFromRemote.ps1
}

try
{
    if($Computer)
    {
        $ishServerModuleName="xISHServer.$ISHServerVersion"
        $remote=Add-ModuleFromRemote -ComputerName $Computer -Credential $Credential -Name $ishServerModuleName
    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'From FTP' {
            Set-ISHToolAntennaHouseLicense -FTPHost $FTPHost -Credential $FTPCredential -FTPPath $FTPPath
            break        
        }
        'From File' {
            $license=Get-Content -Path $FilePath
            Set-ISHToolAntennaHouseLicense -Content $license
            break
        }
    }
}

finally
{
    if($Computer)
    {
        Remove-ModuleFromRemote -Remote $remote
    }
}

Write-Separator -Invocation $MyInvocation -Footer