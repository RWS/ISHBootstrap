Function Get-ISHBootstrapperContextValue
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $ValuePath,
        [Parameter(Mandatory=$false)]
        $DefaultValue=$null
    ) 
    $variableName="__ISHBootstrapper_Data__"

    $data = Get-Variable -Name $variableName -Scope Global -ValueOnly

    $value = Invoke-Expression "`$data.$ValuePath";
    if (-not $value)
    {
        if($DefaultValue)
        {
            $value=$DefaultValue
        }
        else
        {
            Write-Warning "$ValuePath path does not exist and DefaultValue is specified"
        }
    }
    $value
}
