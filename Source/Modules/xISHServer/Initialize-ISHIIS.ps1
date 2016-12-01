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

function Initialize-ISHIIS
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-3EE5FE3E-3E35-452F-9314-DD4775B27CD5
    $appCmdPath=Join-Path $env:windir system32\inetsrv\appcmd
    foreach($subSection in @("asp","serverRuntime","defaultDocument","staticContent","directoryBrowse","handlers","urlCompression"))
    {
        Write-Debug "Unlocking IIS section /section:system.webServer/$subSection"
        & $appCmdPath unlock config "/section:system.webServer/$subSection" /commit:apphost |Out-Null
        Write-Verbose "Unlocked IIS section /section:system.webServer/$subSection"
    }

    $staticcompression = @(
	    @{mimeType='text/*'; enabled='True'}
	    @{mimeType='message/*'; enabled='True'}
	    @{mimeType='application/x-javascript'; enabled='True'}
	    @{mimeType='application/atom+xml'; enabled='True'}
	    @{mimeType='application/xaml+xml'; enabled='True'}
        @{mimeType='application/octet-stream'; enabled='True'}
	    @{mimeType='*/*'; enabled='False'}
    )
    # Set the specified static mimetypes in the compression settings
    # in applicationHost.config
    $filter = 'system.webServer/httpCompression/statictypes'
    Write-Debug "Enabling static compressions on mime types"
    Set-Webconfiguration -Filter $filter -Value $staticcompression
    Write-Verbose "Enabled static compressions on mime types"

    $dynamiccompression = @(
	    @{mimeType='text/*'; enabled='True'}
	    @{mimeType='message/*'; enabled='True'}
	    @{mimeType='application/x-javascript'; enabled='True'}
	    @{mimeType='application/soap+xml'; enabled='True'}
	    @{mimeType='application/xml'; enabled='True'}
	    @{mimeType='application/json'; enabled='True'}
        @{mimeType='application/octet-stream'; enabled='True'}
	    @{mimeType='*/*'; enabled='False'}	
    )
    # Set the specified dynamic mimetypes in the compression settings 
    # in applicationHost.config
    $filter = 'system.webServer/httpCompression/dynamictypes'
    Write-Debug "Enabling dynamic compressions on mime types"
    Set-Webconfiguration -Filter $filter -Value $dynamiccompression
    Write-Verbose "Enabled dynamic compressions on mime types"
    # Note that compression can be set per web.config file	
}
