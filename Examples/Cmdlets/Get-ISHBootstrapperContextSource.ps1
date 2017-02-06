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

Function Get-ISHBootstrapperContextSource
{
    param (
        [Parameter(Mandatory=$false,ParameterSetName="UNC")]
        [switch]$UNC,
        [Parameter(Mandatory=$false,ParameterSetName="FTP")]
        [switch]$FTP,
        [Parameter(Mandatory=$false,ParameterSetName="AWS-S3")]
        [switch]$AWSS3
    ) 
    . "$PSScriptRoot\Get-ISHBootstrapperContextValue.ps1"

    $hash=@{

    }

    switch ($PSCmdlet.ParameterSetName)
    {
        'UNC' {
            $uncData=Get-ISHBootstrapperContextValue -ValuePath "UNC" -DefaultValue $null
            if(-not $uncData)
            {
                return
            }
            $hash.ISHServerFolder=$uncData.ISHServerFolder
            $hash.ISHCDFolder=$uncData.ISHCDFolder
            $hash.AntennaHouseLicensePath=$uncData.AntennaHouseLicensePath
            break        
        }
        'FTP' {
            $ftpData=Get-ISHBootstrapperContextValue -ValuePath "FTP" -DefaultValue $null
            if(-not $ftpData)
            {
                return
            }
            $hash.Host=$ftpData.Host
            $hash.Credential=$ftpData.CredentialExpression|Invoke-Expression
            $hash.ISHServerFolder=$ftpData.ISHServerFolder
            $hash.ISHCDFolder=$ftpData.ISHCDFolder
            $hash.ISHCDFileName=$ftpData.ISHCDFileName
            $hash.AntennaHouseLicensePath=$ftpData.AntennaHouseLicensePath
            break        
        }
        'AWS-S3' {
            $awsS3Data=Get-ISHBootstrapperContextValue -ValuePath "AWSS3" -DefaultValue $null
            if(-not $awsS3Data)
            {
                return
            }
            $hash.BucketName=$awsS3Data.BucketName
            if($awsS3Data.AccessKey -and $awsS3Data.SecretKey)
            {
                $hash.AccessKey=$awsS3Data.AccessKey
                $hash.SecretKey=$awsS3Data.SecretKey
            }
            elseif($awsS3Data.ProfileName)
            {
                $awsCredentials=Get-AWSCredentials -ProfileName $awsS3Data.ProfileName
                $hash.AccessKey=$awsCredentials.GetCredentials().AccessKey
                $hash.SecretKey=$awsCredentials.GetCredentials().SecretKey
            }
            else
            {
                $hash.AccessKey=$null
                $hash.SecretKey=$null
            }
            $hash.ISHServerFolderKey=$awsS3Data.ISHServerFolderKey
            $hash.ISHCDFolderKey=$awsS3Data.ISHCDFolderKey
            $hash.ISHCDFileName=$awsS3Data.ISHCDFileName
            $hash.AntennaHouseLicenseKey=$awsS3Data.AntennaHouseLicenseKey
            break        
        }
    }

    New-Object -TypeName PSObject -Property $hash
}
