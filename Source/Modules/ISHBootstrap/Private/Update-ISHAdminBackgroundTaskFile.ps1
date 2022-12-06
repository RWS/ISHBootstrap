<#
# Copyright (c) 2022 All Rights Reserved by the RWS Group for and on behalf of its affiliates and subsidiaries.
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
   Updates the Vanilla Web\Author\EnterViaUI\Admin.XMLBackgroundTaskConfiguration.xml to reflect AWS architecture
.DESCRIPTION
   Updates the Vanilla Web\Author\EnterViaUI\Admin.XMLBackgroundTaskConfiguration.xml to reflect AWS architecture.
   Renames the service role Default to Multi
   Create new service with role Single
   Move the group for handler SynchronizeToLiveContent from Multi to Single (if found)
   Copy from service role Multi to Single the leaseRevovery and aggrecationRecovery
   Disable from service role Multi the leaseRevovery and aggrecationRecovery
.EXAMPLE
   Update-ISHAdminBackgroundTaskFile
#>
Function Update-ISHAdminBackgroundTaskFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ISHDeployment
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach($psbp in $PSBoundParameters.GetEnumerator()){Write-Debug "$($psbp.Key)=$($psbp.Value)"}
        $ISHDeploymentSplat = @{}
        if ($ISHDeployment) {
            $ISHDeploymentSplat = @{ISHDeployment = $ISHDeployment}
        }
    }

    process {
        # Debug alternative
        # $enterViaUIPath="C:\InfoShare\13.0.0\ISH\WebSQL\Author\EnterViaUI"

        $enterViaUIPath=Get-ISHDeploymentPath -EnterViaUI @ISHDeploymentSplat
        Write-Debug "enterViaUIPath.AbsolutePath=$($enterViaUIPath.AbsolutePath)"
        Write-Debug "enterViaUIPath.RelativePath=$($enterViaUIPath.RelativePath)"
        $filePath=Join-Path -Path $enterViaUIPath.AbsolutePath -ChildPath "Admin.XMLBackgroundTaskConfiguration.xml"
        $backupRelativePath="$($enterViaUIPath.RelativePath)\Admin.XMLBackgroundTaskConfiguration.xml"
        Write-Debug "filePath=$filePath"
        Write-Debug "backupRelativePath=$backupRelativePath"
        Backup-ISHDeployment -Path $backupRelativePath -Web @ISHDeploymentSplat

        [xml]$xml=Get-Content -Path $filePath -Raw

        # Test if the file is already compatible with Single/Multi role concept
        $xpathMultiService='infoShareBackgroundTaskConfig/services/service[@role="Multi"]'
        $xpathSingleService='infoShareBackgroundTaskConfig/services/service[@role="Single"]'

        $xpathGroupSynchronizeToLiveContent='infoShareBackgroundTaskConfig/services/service[@role="Default"]/matrix/group[@name="SynchronizeToLiveContent"]'
        $xpathDefaultService='infoShareBackgroundTaskConfig/services/service[@role="Default"]'
        $xpathServices='infoShareBackgroundTaskConfig/services'

        Write-Debug "xpathGroupSynchronizeToLiveContent=$xpathGroupSynchronizeToLiveContent"
        Write-Debug "xpathDefaultService=$xpathDefaultService"
        Write-Debug "xpathServices=$xpathServices"

        if($xml.SelectSingleNode($xpathMultiService) -and $xml.SelectSingleNode($xpathSingleService))
        {
            Write-Verbose "$filePath is already aligned with the Single/Multi Background Task role architecture"
        }
        elseif ((-not $xml.SelectSingleNode($xpathGroupSynchronizeToLiveContent)) -and (-not $xml.SelectSingleNode($xpathDefaultService)))
        {
            Write-Verbose "$filePath does not contain the SynchronizeToLiveContent node, nor a service with the 'Default' role. Assuming it is already aligned with the (Single/)Multi Background Task role architecture"
        }
        else
        {
            # Remove comment nodes, because they interfere with the comment we put around this element.
            foreach ($comment in $xml.SelectNodes("$xpathGroupSynchronizeToLiveContent//comment()"))
            {
                $comment.ParentNode.RemoveChild($comment);
            }
            # Get node for group for SynchronizeToLiveContent
            $nodeDefaultService=$xml.SelectSingleNode($xpathDefaultService)
            $nodeGroupSynchronizeToLiveContent=$xml.SelectSingleNode($xpathGroupSynchronizeToLiveContent)
            $nodeServices=$xml.SelectSingleNode($xpathServices)

            if ($nodeGroupSynchronizeToLiveContent)
            {
                # Comment the group for SynchronizeToLiveContent inside Service node with name Default
                $commentExplanation = $xml.CreateComment("Automation changes: Group for SynchronizeToLiveContent is moved to service with role Single. Don't edit");
                $commentedNode = $xml.CreateComment($nodeGroupSynchronizeToLiveContent.OuterXml);

                $null=$nodeDefaultService.Matrix.InsertBefore($commentExplanation,$nodeGroupSynchronizeToLiveContent)
                $null=$nodeDefaultService.Matrix.ReplaceChild($commentedNode, $nodeGroupSynchronizeToLiveContent);
            }

            # Change the role from Default to Multi
            $commentExplanation = $xml.CreateComment("Automation changes: Role name changed to Multi. Don't edit");
            $nodeDefaultService.role="Multi"
            $null=$nodeServices.InsertBefore($commentExplanation,$nodeDefaultService)

            if ($nodeGroupSynchronizeToLiveContent)
            {
                # Create new service with role Single
                $nodeSingleService=$xml.CreateElement("service")
                $null=$nodeSingleService.SetAttribute("role","Single")
                $nodeMatrix=$nodeSingleService.AppendChild($xml.CreateElement("matrix"))
                $null=$nodeSingleService.AppendChild($nodeDefaultService.leaseRecovery.CloneNode($true))
                $null=$nodeSingleService.AppendChild($nodeDefaultService.poller.CloneNode($true))
                $null=$nodeSingleService.AppendChild($nodeDefaultService.aggregationRecovery.CloneNode($true))
                $commentExplanation = $xml.CreateComment("Automation changes: Group for SynchronizeToLiveContent was moved from service with role Default/Multi. Don't edit");
                $null=$nodeMatrix.AppendChild($commentExplanation)
                $null=$nodeMatrix.AppendChild($nodeGroupSynchronizeToLiveContent)
                $commentExplanation = $xml.CreateComment("Automation changes: Service for role Single. Don't edit");
                $null=$nodeServices.InsertAfter($commentExplanation,$nodeDefaultService)
                $null=$nodeServices.InsertAfter($nodeSingleService,$commentExplanation)
            }

            # Allow Only polling for the Service with role Multi
            $nodeDefaultService.leaseRecovery.isEnabled="false"
            $nodeDefaultService.aggregationRecovery.isEnabled="false"
            $commentExplanation = $xml.CreateComment("Automation changes: Lease recovery responsibility moved to service with role Single. Don't edit");
            $null=$nodeDefaultService.InsertBefore($commentExplanation,$nodeDefaultService.leaseRecovery)
            $commentExplanation = $xml.CreateComment("Automation changes: Aggregation recovery responsibility moved to service with role Single. Don't edit");
            $null=$nodeDefaultService.InsertBefore($commentExplanation,$nodeDefaultService.aggregationRecovery)

            $xml.Save($filePath)
            Write-Verbose "$filePath adapted to align with the Single/Multi Backround Task role architecture"
        }
    }

    end {

    }
}

