#reguires -runasadministrator

param(
    [Parameter(Mandatory=$false,ParameterSetName="Nuget")]
    [switch]$Nuget,
    [Parameter(Mandatory=$false,ParameterSetName="Separate")]
    [hashtable[]]$PowerShellGetScripts=$null,
    [Parameter(Mandatory=$false,ParameterSetName="Separate")]
    [hashtable[]]$PowerShellGetModules=$null,
    [Parameter(Mandatory=$false,ParameterSetName="Separate")]
    [hashtable[]]$GitHub=$null,
    [Parameter(Mandatory=$true,ParameterSetName="Grouped")]
    [hashtable]$Prerequisites,
    [Parameter(Mandatory=$false,ParameterSetName="Nuget")]
    [Parameter(Mandatory=$false,ParameterSetName="Separate")]
    [Parameter(Mandatory=$false,ParameterSetName="Grouped")]
    [switch]$WhatIf=$false
)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Get-ProgressHash.ps1"
Write-Separator -Invocation $MyInvocation -Header
$scriptProgress=Get-ProgressHash -Invocation $MyInvocation

try 
{
    switch($PSCmdlet.ParameterSetName)
    {
        'Nuget' {
            $blockName="Installing NuGet PackageProvider" 
            Write-Progress @scriptProgress -Status $blockName
            Write-Host $blockName

            Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null
            return
        }
        'Grouped' {
            if($Prerequisites.ContainsKey("PowerShellGetScripts"))
            {
                $PowerShellGetScripts=$Prerequisites.PowerShellGetScripts
            }
            if($Prerequisites.ContainsKey("PowerShellGetModules"))
            {
                $PowerShellGetModules=$Prerequisites.PowerShellGetModules
            }
            if($Prerequisites.ContainsKey("GitHub"))
            {
                $GitHub=$Prerequisites.GitHub
            }
        }
        'Separate' {

        }
    }


    #region guarantee pre-requisites
    
    # If there are Github Prerequisites then we need to make that [Get-Github.ps1](https://www.powershellgallery.com/packages/Get-Github/) is available
    if($GitHub)
    {
        if(-not $PowerShellGetScripts)
        {
            $PowerShellGetScripts=@()
        }
        if(-not ($PowerShellGetScripts |Where-Object {$_.Name -eq "Get-Github"}))
        {
            $PowerShellGetScripts+=@{
                Name="Get-Github"
            }
        }
    }

    #endregion

    #region PowerShellGet
    if($PowerShellGetScripts)
    {

        $PowerShellGetScripts |ForEach-Object {
            $hash=$_

            $blockName="Installing powershell script $($_.Name)"
            Write-Progress @scriptProgress -Status $blockName
            Write-Host $blockName

            Install-Script @hash -Force -WhatIf:$WhatIf
        }
        
        if(-not $WhatIf)
        {
            New-Object -Type PSObject -Property ([ordered]@{
                Name="ProfileScriptsPath"
                Type="PowerShellGetScripts"
                Path=Join-Path $env:ProgramFiles "WindowsPowerShell\Scripts"
            })
        }
    }
    if($PowerShellGetModules)
    {

        $PowerShellGetModules |ForEach-Object {
            $hash=$_

            $blockName="Installing powershell module $($_.Name)"
            Write-Progress @scriptProgress -Status $blockName
            Write-Host $blockName

            Install-Module @hash -Force -WhatIf:$WhatIf
        }
    }
    #endregion

    #region Github
    if($GitHub)
    {
        $getGithubPath=Join-Path $env:ProgramFiles "WindowsPowerShell\Scripts\Get-Github.ps1"

        $GitHub |ForEach-Object {
            $blockName="Performing action Get-Github for repository $($_.User)/$($_.Repository)"
            Write-Progress @scriptProgress -Status $blockName
            Write-Host $blockName
            if(-not $WhatIf)
            {
                $hash=$_
                Write-Host "Installing GitHub repository $($_.Repository)"
                $expandedPath=& $getGithubPath @hash -Expand|Select-Object -ExpandProperty FullName
                New-Object -Type PSObject -Property ([ordered]@{
                    Name=$_.Repository
                    Type="GitHub"
                    Path=$expandedPath
                })
            }
        }

    }
    #endregion
}
finally
{

}

Write-Progress @scriptProgress -Completed
Write-Separator -Invocation $MyInvocation -Footer