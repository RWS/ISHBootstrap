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

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$uninstallBlock= {
    $rootPath="C:\ISHCD\$ishVersion"
    Write-Debug "rootPath=$rootPath"

    $cdPath=(Get-ChildItem $rootPath |Where-Object{Test-Path $_.FullName -PathType Container}| Sort-Object FullName -Descending)|Select-Object -ExpandProperty FullName -First 1
    Write-Debug "cdPath=$cdPath"
    if(-not $cdPath)
    {
        Write-Warning "C:\ISHCD\$ishVersion does not contain a cd."
        return
    }

    $ishDeployModuleName="ISHDeploy.$ishVersion"
    if(Get-Module $ishDeployModuleName -ListAvailable)
    {
        Get-ISHDeployment |Select-Object -ExpandProperty Name | ForEach-Object {
            Write-Debug "Uninstalling from $cdPath the deployment $_"
            Uninstall-ISHDeployment -CDPath $cdPath -Name $_
            Write-Verbose "Uninstalled from $cdPath the deployment $_"
        }
    }
    else
    {
        Write-Warning "$ishDeployModuleName is not available. Falling back into working with the files created by Install-ISH.ps1 ($rootPath\inputparameters-*.xml)"
        $inputParameterFiles=Get-ChildItem $rootPath -Filter "inputparameters-*.xml"

        $inputParameterFiles | ForEach-Object {
            $fileName=$_.Name
            if ($fileName -match "inputparameters-(?<name>.*)\.xml")
            {
                $name=$Matches["name"]
                Write-Debug "Uninstalling from $cdPath the deployment $name"
                Uninstall-ISHDeployment -CDPath $cdPath -Name $name
                Write-Verbose "Uninstalled from $cdPath the deployment $name"
            }
            else
            {
                Write-Warning "Not a valid input parameter file $fileName"
            }
        }
    }
}

try
{

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }
    Invoke-CommandWrap -ComputerName $computerName -Credential $credential -ScriptBlock $uninstallBlock -BlockName "Uninstall ISH" -UseParameters @("ishVersion")

}
finally
{
}
