param (
    [Parameter(Mandatory=$false)]
    [string[]]$Computer,
    [Parameter(Mandatory=$true)]
    [string[]]$ModuleName,
    [Parameter(Mandatory=$false)]
    [string]$Repository,
    [Parameter(Mandatory=$false)]
    [ValidateSet("AllUsers","CurrentUser")]
    [string]$Scope="AllUsers"
)    

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-MyInvocation.ps1"
Write-MyInvocation -Invocation $MyInvocation

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
            Write-Error "Could not find package $name"
            return
        }
        Write-Verbose "Found module $name with version $($latestModule.Version)"
        Write-Verbose "Installing module $name with version $($latestPackage.Version)"

        $latestModule|Install-Module -Scope $Scope -Force|Out-Null
   
        Write-Host "Installed module $name with version $($latestModule.Version)"
    }
}

#Install the packages
try
{
    Invoke-CommandWrap -ComputerName $Computer -ScriptBlock $installScriptBlock -BlockName "Install Modules $ModuleName" -UseParameters @("ModuleName","Repository","Scope")
}
catch
{
    Write-Error $_
}



