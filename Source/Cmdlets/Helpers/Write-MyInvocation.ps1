Function Write-MyInvocation {
    param (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.InvocationInfo]$Invocation
    )
    $lines=@()
    $lines+="Invoke script"
    $lines+=$Invocation.MyCommand.Definition
    Write-Verbose ($lines -join ' ')
}