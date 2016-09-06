Function Write-Separator {
    param (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.InvocationInfo]$Invocation,
        [Parameter(Mandatory=$true,ParameterSetName="Header")]
        [switch]$Header,
        [Parameter(Mandatory=$true,ParameterSetName="Footer")]
        [switch]$Footer
    )
    $segments=@()
    if($Header)
    {
        $segments+="Begin"
    }
    if($Footer)
    {
        $segments+="End"
    }
    $segments+="Script"
    $line="["+($segments -join ' ')+"]"+" "+$Invocation.MyCommand.Definition
    Write-Host $line -ForegroundColor White -BackgroundColor Black
    if($Footer)
    {
        Write-Host ""
    }
}