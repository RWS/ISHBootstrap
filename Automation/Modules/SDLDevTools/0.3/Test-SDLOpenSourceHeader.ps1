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

Function Test-SDLOpenSourceHeader {
    param(
        [Parameter(Mandatory=$true,ParameterSetName="Folder")]
        [string]$FolderPath,
        [Parameter(Mandatory=$false,ParameterSetName="Folder")]
        [string[]]$ExcludeFolder=$null,
        [Parameter(Mandatory=$false,ParameterSetName="Folder")]
        [string[]]$ExcludeExtension=$null,
        [Parameter(Mandatory=$true,ParameterSetName="File")]
        [string]$FilePath,
        [Parameter(Mandatory=$false,ParameterSetName="File")]
        [Parameter(Mandatory=$false,ParameterSetName="Folder")]
        [switch]$PassThru=$false,
        [Parameter(Mandatory=$false,ParameterSetName="File")]
        [Parameter(Mandatory=$false,ParameterSetName="Folder")]
        [switch]$ExpandError=$false
    )
    begin {
        . $PSScriptRoot\Get-SDLOpenSourceHeader.ps1
        . $PSScriptRoot\Get-SDLOpenSourceHeaderFormat.ps1
    }
    process {
        switch($PSCmdlet.ParameterSetName)
        {
            'Folder' {
                Get-ChildItem $FolderPath -Filter "*.*" -Recurse -File | ForEach-Object {
                    $fullName=$_.FullName
                    $extension=$_.Extension
                    if(-not ($fullName))
                    {
                        return
                    }
                    if($ExcludeExtension -contains $_.Extension)
                    {
                        return
                    }
                    if($ExcludeFolder | Where-Object {
                        $fullName -like "*\$_\*"
                    }){
                        return
                    }
                    Test-SDLOpenSourceHeader -FilePath ($_.FullName) -PassThru:$PassThru -ExpandError:$ExpandError
                }
            }
            'File' {
                Write-Debug "Calculating format for $FilePath"
                $fileFormat=Get-SDLOpenSourceHeaderFormat -FilePath $FilePath
                if(-not $fileFormat)
                {
                     Write-Warning "Skipped $FilePath"
                     break
                }
                Write-Debug "Testing header for $FilePath"
                $header = Get-SDLOpenSourceHeader -Format $fileFormat
                $content=Get-Content $FilePath

                $errors=@()
                if($content.Count -lt $header.Count)
                {
                    $errors+="Line count less than header"
                }
                else
                {
                    $numberOfLinesToCompare=$header.Count
                    #Normally there should be a separator between the header and the first line
                    if($content[$header.Count-1] -ne $header[$header.Count])
                    {
                        # When it's not the comparison is going to be more linient by not comparing the last "empty line"
                        $numberOfLinesToCompare=$header.Count-1
                    }
                    $fileHeader=$content|Select-Object -First $numberOfLinesToCompare
                    $linesWithErrors=@()
                    for($i=0;$i -lt $numberOfLinesToCompare;$i++)
                    {
                        if($header[$i] -ne $content[$i])
                        {
                            if($ExpandError)
                            {
                                $errors+="Line $($i+1) actual:$($content[$i])"
                                $errors+="Line $($i+1) expected:$($header[$i])"
                            }
                            else
                            {
                                $linesWithErrors+=$i+1
                            }
                        }
                    }
                    if((-not $ExpandError) -and $linesWithErrors.Count -gt 0)
                    {
                        $errors+="Lines $($linesWithErrors -join ',') don't match"
                    }
                }
                $isValid=$errors.Count -eq 0
                if($isValid)
                {
                    $hash=[ordered]@{
                        FilePath=$FilePath
                        Format=$fileFormat
                        Error=$null
                        IsValid=$isValid
                    }
                }
                else
                {
                    $hash=@()
                    $errors|ForEach-Object {
                        $hash+=[ordered]@{
                            FilePath=$FilePath
                            Format=$fileFormat
                            Error=$_
                            IsValid=$isValid
                        }
                    }
                }
                Write-Verbose "Tested header for $FilePath"
                if($PassThru)
                {
                    $hash|ForEach-Object {
                        New-Object -TypeName PSObject -Property $_
                    }
                }
                else
                {
                    if(-not $isValid)
                    {
                        $errorLines=@()
                        $errorLines+="Failed for $FilePath because"
                        $errorLines+=$errors
                        $errorMessage=$errorLines-join [System.Environment]::NewLine
                        Write-Error $errorMessage
                    }
                    $hash.IsValid
                }
            }
        }
    }

    end {

    }
}