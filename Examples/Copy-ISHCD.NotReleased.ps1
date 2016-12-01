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

if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
$credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke
$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
$ishServerVersion=($ishVersion -split "\.")[0]

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$internalCDFolder=Get-ISHBootstrapperContextValue -ValuePath "InternalRelease.ISHCDFolder"

$copyBlock= {
    $targetPath="C:\IshCD\$ishVersion"
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

    if($ISHServerVersion -eq "12") 
    {
        $arguments=@("-d$targetPath","-s")
    }
    else 
    {
        $arguments=@(
            "-y" 
            "-gm2" 
            "-InstallPath=`"$($targetPath.Replace('\','\\'))`"" 
        )
    }

    Write-Debug "Unzipping $cdPath in $targetPath"
    Start-Process $cdPath -ArgumentList $arguments -Wait
    Write-Host "Unzipped $cdPath in $targetPath"
}

try
{

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
		$session=$null
    }
    else
    {
        $fqdn=[System.Net.Dns]::GetHostByName($computerName)| FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
        if(Get-ISHBootstrapperContextValue -ValuePath "Domain")
        {
            if($credential)
            {		
                $session=New-PSSession -ComputerName $fqdn -Credential $credential -UseSSL -Authentication Credssp
            }
            else
            {
                $session=New-PSSession -ComputerName $fqdn -UseSSL -Authentication Credssp
            }
        }
        else
        {
            if($credential)
            {		
                $session=New-PSSession -ComputerName $fqdn -Credential $credential
            }
            else
            {
                $session=New-PSSession -ComputerName $fqdn
            }
        }
    }

    Invoke-CommandWrap -Session $session -ScriptBlock $copyBlock -BlockName "Copy and Extract ISH.$ishVersion" -UseParameters @("ishVersion","internalCDFolder")

}
finally
{
    if($session)
    {
        Remove-PSSession $session
        $session=$null
    }
}
