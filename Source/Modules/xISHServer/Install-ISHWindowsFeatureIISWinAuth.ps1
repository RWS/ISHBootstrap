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

function Install-ISHWindowsFeatureIISWinAuth
{
    <#
    ServerManager is expected in Windows Server operating system.
    In a client OS like Windows 7,8 or 10, ServerManager is not available. 
    Instead there is DISM. 
    Server and DISM are much alike but the name of cmdlet, the terms and flow is a bit different.
    With DISM you need to check if a feature is installed before installing it.

    #>
    if(Get-Module ServerManager -ListAvailable)
    {
        $featureNames=@(
            "Web-Windows-Auth"
        )
        Install-WindowsFeature -Name $featureNames |Out-Null
    }
    elseif(Get-Module DISM -ListAvailable)
    {
        Write-Warning "DISM module was found instead of ServerManager. This should happen only in non Server operating systems."
        $features=@(
            "IIS-WindowsAuthentication"
        )

        $notInstalledFeatures=$features|ForEach-Object {
            $feature=Get-WindowsOptionalFeature -FeatureName $_ -Online
            if($feature.State -eq "Enabled")
            {
                Write-Warning "$($feature.FeatureName) is already installed"
            }
            else
            {
                Write-Verbose "$($feature.FeatureName) will be installed"
                $feature
            }
        }
        #$notInstalledFeatures|Format-Table
        $notInstalledFeatures| ForEach-Object {
            try
            {
                $featureName=$_.FeatureName
                Enable-WindowsOptionalFeature -FeatureName $featureName -Online -All
                Write-Host "Enabled feature $featureName"
            }
            catch
            {
                Write-Error "Error for $featureName"
                Write-Error "$_"
            }
        }
    }
    else
    {
        Write-Error "Cannot find ServerManager nor DISM powershell modules installed"
    }
}
