Function Get-ISHBootstrapperContextValue
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $ValuePath
    ) 
    $variableName="__ISHBootstrapper_Data__"

    $data = Get-Variable -Name $variableName -Scope Global -ValueOnly

    $value = $data.$ValuePath;
    if (-not $value)
    {
        Write-Warning "$ValuePath path does not exist or is null"
    }
    $value
}
