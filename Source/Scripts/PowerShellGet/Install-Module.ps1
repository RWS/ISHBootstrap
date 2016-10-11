param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$false)]
    [pscredential]$Credential=$null,
    [Parameter(Mandatory=$true)]
    [string[]]$ModuleName,
    [Parameter(Mandatory=$false)]
    [string]$Repository,
    [Parameter(Mandatory=$false)]
    [ValidateSet("AllUsers","CurrentUser")]
    [string]$Scope="AllUsers"
)    

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$installScriptBlock={
    foreach($name in $ModuleName)
    {
    
        Write-Debug "Finding modules $name"
        if($Repository)
        {
            $latestModule=Find-Module -Name $name -Repository $Repository |Where-Object {$_.Name -eq $name}
        }
        else
        {
            $latestModule=Find-Module -Name $name |Where-Object {$_.Name -eq $name}
        }

        if(-not $latestModule)
        {
            Write-Error "Could not find module $name"
            return
        }
        Write-Verbose "Found module $name with version $($latestModule.Version)"

        $latestModule|Install-Module -Scope $Scope -Force|Out-Null
   
        Write-Host "Installed module $name with version $($latestModule.Version)"
    }
}

#Install the packages
try
{
    Invoke-CommandWrap -ComputerName $Computer -Credential $Credential -ScriptBlock $installScriptBlock -BlockName "Install Modules $ModuleName" -UseParameters @("ModuleName","Repository","Scope")
}
catch
{
    Write-Error $_
}

Write-Separator -Invocation $MyInvocation -Footer