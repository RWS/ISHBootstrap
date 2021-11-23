<#
# Copyright (c) 2021 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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

<#
.Synopsis
   Test what is changed from AWS SSM parameter store on the deployment
.DESCRIPTION
   Produce an object with what is changed from AWS SSM parameter store on the deployment
.EXAMPLE
   Test-ISHCoreConfiguration
#>
function Test-ISHCoreConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        $ConfigurationData = $null,
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
    }

    process {
        if (-not $ConfigurationData) {
            $ConfigurationData = Get-ISHCoreConfiguration
        }

        $hash = @{
            EC2InitializedFromAMI = Test-ISHRequirement -Marker -Name "ISH.EC2InitializedFromAMI"

            #Database
            Database              = (Get-ISHDeploymentParameters -Name connectstring -ValueOnly @ISHDeploymentSplat) -eq $ConfigurationData.Database.ConnectionString
            OSUser                = (($null -eq $ConfigurationData.OSUser) -or (((Get-ISHDeploymentParameters -Name osuser -ValueOnly @ISHDeploymentSplat) -eq $ConfigurationData.OSUser.NormalizedUsername) -and ((Get-ISHDeploymentParameters -Name ospassword -ValueOnly -ShowPassword @ISHDeploymentSplat) -eq $ConfigurationData.OSUser.Password)))
            ServiceUser           = (($null -eq $ConfigurationData.ServiceUser) -or (((Get-ISHDeploymentParameters -Name serviceusername -ValueOnly @ISHDeploymentSplat) -eq $ConfigurationData.ServiceUser.Username) -and ((Get-ISHDeploymentParameters -Name servicepassword -ValueOnly -ShowPassword @ISHDeploymentSplat) -eq $ConfigurationData.ServiceUser.Password)))
            Crawler               = ($ConfigurationData.Service.Crawler.Count) -eq ((Get-ISHServiceCrawler @ISHDeploymentSplat).Count)
            TranslationBuilder    = ($ConfigurationData.Service.TranslationBuilder.Count) -eq ((Get-ISHServiceTranslationBuilder @ISHDeploymentSplat).Count)
            TranslationOrganizer  = ($ConfigurationData.Service.TranslationOrganizer.Count) -eq ((Get-ISHServiceTranslationOrganizer @ISHDeploymentSplat).Count)
            BackgroundTaskDefault = ($ConfigurationData.Service.BackgroundTaskDefault.Count) -eq ((Get-ISHServiceBackgroundTask @ISHDeploymentSplat | Where-Object -Property Role -EQ Default).Count)
            BackgroundTaskSingle  = ($ConfigurationData.Service.BackgroundTaskSingle.Count) -eq ((Get-ISHServiceBackgroundTask @ISHDeploymentSplat | Where-Object -Property Role -EQ Single).Count)
            BackgroundTaskMulti   = ($ConfigurationData.Service.BackgroundTaskMulti.Count) -eq ((Get-ISHServiceBackgroundTask @ISHDeploymentSplat | Where-Object -Property Role -EQ Multi).Count)
        }

        New-Object -TypeName PSObject -Property $hash

    }

    end {

    }
}
