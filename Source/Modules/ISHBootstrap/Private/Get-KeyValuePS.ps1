<#
.Synopsis
   Get one or more keys from json file
.DESCRIPTION
   Get from json file the following for a given key
   - Key and value
   - Only keys
   - Value
   - Blob
.EXAMPLE
   Get-KeyValuePS -Key key
.EXAMPLE
   Get-KeyValuePS -Key key -Recurse
.EXAMPLE
   Get-KeyValuePS -Key key -OnlyValue
.EXAMPLE
   Get-KeyValuePS -Key key -OnlyKeys
.EXAMPLE
   Get-KeyValuePS -Key key -Blob
#>
Function Get-KeyValuePS {
    [OutputType([Byte[]])]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "Key/Value")]
        [Parameter(Mandatory = $true, ParameterSetName = "Key/Blob")]
        [Parameter(Mandatory = $false, ParameterSetName = "List Keys")]
        [string]$Key,
        [Parameter(Mandatory = $true, ParameterSetName = "Key/Value")]
        [Parameter(Mandatory = $true, ParameterSetName = "Key/Blob")]
        [Parameter(Mandatory = $true, ParameterSetName = "List Keys")]
        [ValidateScript( {
                if (-Not ($_ | Test-Path -PathType Leaf) ) {
                    throw "The Path argument must be an existing file."
                }
                return $true
            })]
        [string]$FilePath,
        [Parameter(Mandatory = $true, ParameterSetName = "List Keys")]
        [switch]$OnlyKeys,
        [Parameter(Mandatory = $false, ParameterSetName = "Key/Value")]
        [switch]$Recurse = $false,
        [Parameter(Mandatory = $false, ParameterSetName = "Key/Value")]
        [switch]$OnlyValue = $false,
        [Parameter(Mandatory = $true, ParameterSetName = "Key/Blob")]
        [switch]$Blob
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        # Derive splat from PSBoundParameters
        $newBoundParameters = @{ } + $PSBoundParameters
        $null = $newBoundParameters.Remove('OnlyValue')
        if ($PSCmdlet.ParameterSetName -eq "Key/Blob") {
            $null = $newBoundParameters.Add('Raw', $true)
            $null = $newBoundParameters.Remove('Blob')
        }
    }

    process {

        function Get-ParametersByPath {
            param (
                $Key,
                $hash
            )
            $path = $Key.Trim("/").Replace('/', "'.'")
            $sub = Invoke-Expression "`$hash.'$path'"
            if ($sub) {
                return ConvertNestedHastableToKeyValues $Key.Trim("/") $sub | Sort-Object -Property key
            }
            else {
                $null
            }
        }
        function ConvertJSONToNestedHashtable {
            [CmdletBinding()]
            [OutputType('hashtable')]
            param(
                [Parameter(ValueFromPipeline)]
                $root
            )
            $hash = @{ }

            if ([string]::IsNullOrEmpty($root)) {
                return $hash
            }

            $keys = $root | Get-Member -MemberType NoteProperty | Select-Object -exp Name

            $keys | ForEach-Object {
                $key = $_
                $obj = $root.$($_)
                if ($obj -match "@{") {
                    $nesthash = ConvertJSONToNestedHashtable $obj
                    $hash.add($key, $nesthash)
                }
                else {
                    if($null -eq $obj)
                    {
                        $obj='null'
                    }
                    $hash.add($key, $obj)
                }
            }
            return $hash
        }
        function ConvertNestedHastableToKeyValues {
            param(
                $path,
                $j
            )

            $pathPre = ""
            if ($path -ne "") {
                $pathPre = $path + "/"
            }

            if ($null -eq $j) {
                $type = "null"
            }
            else {
                $type = $j.GetType().Name
            }
            switch ($type) {
                "Hashtable" {
                    foreach ($h in $j.GetEnumerator()) {
                        $sk = $h.Name
                        $sv = $h.Value
                        $newpath = $pathPre + $sk
                        ConvertNestedHastableToKeyValues $newpath $sv
                    }
                    break
                }
                default {
                    $KV = CreateKeyValueObject $path $j
                    break
                }
            }
            $KV
        }
        Function CreateKeyValueObject {
            param(
                $key,
                $value
            )

            $KV = New-Object -TypeName psobject

            $KV | Add-Member -MemberType NoteProperty -Name Key -Value $key
            $KV | Add-Member -MemberType NoteProperty -Name Value -Value $value

            return $KV
        }

        try {
            $nestedhashGitConfiguration = (Get-Content -Raw -Path $FilePath | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString("$_") } | ConvertFrom-Json | ConvertJSONToNestedHashtable)
        }
        catch {
            throw
        }
        $result = Get-ParametersByPath $Key $nestedhashGitConfiguration
        switch ($PSCmdlet.ParameterSetName) {
            'List Keys' {
                return $result.Key
            }
            'Key/Value' {
                if ($PSBoundParameters.ContainsKey("Recurse") -and !$OnlyValue) {
                    Write-Verbose "Key/Value Recurse"
                    return $result
                }
                else {
                    if (-not $result.Key -or $result.Key -ne $Key) {
                        return $null
                    }
                    if ($OnlyValue) {
                        return $result.Value
                    }
                    else {
                        return $result
                    }
                }
            }
            'Key/Blob' {
                if (-not $result.Value.ToString() -or $result.GetType().Name -eq "Object[]") {
                    return $null
                }
                else {
                    return [System.Convert]::FromBase64String($result.Value)
                }
            }
        }
    }

    end {

    }
}