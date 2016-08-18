. $PSScriptRoot\Invoke-CommandWrap.ps1

Function Remove-ModuleFromRemote {
    param (
        [Parameter(Mandatory=$false)]
        [PSObject]$Remote=$null
    ) 
    if($Remote)
    {
        $Remote.Module | ForEach-Object { 
            Get-Module -Name $_| Remove-Module
            Write-Host "Removed remote module $_"
        }
        if($Remote.Session)
        {
            $Remote.Session|Remove-PSSession
        }
    }
}