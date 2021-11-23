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

Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
foreach($psbp in $PSBoundParameters.GetEnumerator()){Write-Debug "$($psbp.Key)=$($psbp.Value)"}

#region Implementation
# Resubmit Xml Settings is idempotent, force resubmit always from prepared EnterViaUI folder
$ps1FilePath = "$PSScriptRoot\Settings\Set-XmlSettings.ps1"
Write-Debug ("Calling[$ps1FilePath]")
& $ps1FilePath

#endregion Implementation
