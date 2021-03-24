<#
.Synopsis
   Get the key
.DESCRIPTION
   Gets the key from tags
.EXAMPLE
   Get-Key -ProjectStage
.EXAMPLE
   Get-Key -ISH
.EXAMPLE
   Get-Key -Custom
#>
Function Get-Key {
    [OutputType([String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "DebugReroute")]
        [switch]$DebugReroute,
        [Parameter(Mandatory = $true, ParameterSetName = "Project+Stage")]
        [switch]$ProjectStage,
        [Parameter(Mandatory = $true, ParameterSetName = "ISH")]
        [switch]$ISH,
        [Parameter(Mandatory = $true, ParameterSetName = "Custom")]
        [switch]$Custom
    )

    begin {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach ($psbp in $PSBoundParameters.GetEnumerator()) { Write-Debug "$($psbp.Key)=$($psbp.Value)" }

        $codeVersion = Get-Tag -Name "CodeVersion"
        Write-Debug "codeVersion=$codeVersion"
        if ($PSCmdlet.ParameterSetName -ne "DebugReroute") {
            $project = Get-Tag -Name "Project"
            $stage = Get-Tag -Name "Stage"
            Write-Debug "project=$project"
            Write-Debug "stage=$stage"
        }
    }

    process {

        if ($PSCmdlet.ParameterSetName -eq "DebugReroute") {
            if ($codeVersion -like "debug-*") {
                "$codeVersion/Debug"
            }
            else {
                throw "DebugReroute operations not allowed for codeversion $codeVersion"
            }
        }
        else {
            if ($codeVersion -like "debug-*") {
                $debugCodeVersion = Get-DebugReroute @PSBoundParameters
                if ($debugCodeVersion) {
                    Write-Warning "[DEBUG]Rerouting $codeVersion to $debugCodeVersion"
                    $codeVersion = $debugCodeVersion
                }
            }
            switch ($PSCmdlet.ParameterSetName) {
                'Project+Stage' {
                    "$codeVersion/Project/$project/$stage"
                }
                'ISH' {
                    "$codeVersion/Project/$project/$stage/ISH"
                }
                'Custom' {
                    "$codeVersion/Project/$project/$stage/Custom"
                }
            }
        }
    }

    end {

    }
}