Function Write-Separator {
    param (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.InvocationInfo]$Invocation,
        [Parameter(Mandatory=$true,ParameterSetName="Header")]
        [switch]$Header,
        [Parameter(Mandatory=$true,ParameterSetName="Footer")]
        [switch]$Footer,
        [Parameter(Mandatory=$false)]
        [string]$Name="Script"
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
    $segments+=$Name
    if($Invocation.BoundParameters.DeploymentName)
    {
        $segments+="/"+$($Invocation.BoundParameters.DeploymentName)
    }
    if($Invocation.BoundParameters.Session)
    {
        $segments+="@"+$($Invocation.BoundParameters.Session.ComputerName)
    }
    $line="["+($segments -join ' ')+"]"+" "+$Invocation.MyCommand.Definition
    Write-Host $line -ForegroundColor White -BackgroundColor Black
    if($Footer)
    {
        Write-Host ""
    }
}