if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$internalCDFolder=Get-ISHBootstrapperContextValue -ValuePath "InternalRelease.ISH1201CDFolder"

$copyBlock= {
    $targetPath="C:\IshCD\12.0.1"
    Write-Debug "targetPath=$targetPath"

    $cdObject=((Get-ChildItem $internalCDFolder |Where-Object{Test-Path $_.FullName -PathType Leaf}| Sort-Object FullName -Descending)[0])
    Write-Debug "cdObject=$($cdObject.FullName)"

    Copy-Item $cdObject.FullName $env:TEMP
    $cdPath=Join-Path $env:TEMP $cdObject.Name
    Write-Debug "Copied file $($cdObject.FullName) to $cdPath"

    Write-Debug "targetPath=$targetPath"
    if(-not (Test-Path $targetPath))
    {
        New-Item $targetPath -ItemType Directory | Out-Null
    }
    Remove-Item "$targetPath\*" -Force -Recurse
    Write-Verbose "$targetPath is ready"

    $arguments=@("-d$targetPath","-s")
    Write-Debug "Unzipping $cdPath in $targetPath"
    Start-Process $cdPath -ArgumentList $arguments -Wait
    Write-Host "Unzipped $cdPath in $targetPath"
}

try
{

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }
    else
    {
        $fqdn=[System.Net.Dns]::GetHostByName($computerName)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
        $credentialForCredSSP=Invoke-Expression (Get-ISHBootstrapperContextValue -ValuePath "CredentialForCredSSPExpression")
    }
    $session=New-PSSession -ComputerName $fqdn -Credential $credentialForCredSSP -UseSSL -Authentication Credssp

    Invoke-CommandWrap -Session $session -ScriptBlock $copyBlock -BlockName "Copy and Extract ISH12.0.1" -UseParameters @("internalCDFolder")

}
finally
{
    if($session)
    {
        Remove-PSSession $session
        $session=$null
    }
}
