<#
.Synopsis
   Get the recipe metadata from the active execution
.DESCRIPTION
   Get the recipe metadata from the active execution
   This cmdlet has meaningful execution only when executed from within a recipe's script
.EXAMPLE
   Get-RecipeMetadata
#>
function Get-RecipeMetadata
{
    [CmdletBinding()]
    param (

    )

    begin
    {
        Write-Debug "PSCmdlet.ParameterSetName=$($PSCmdlet.ParameterSetName)"
        foreach($psbp in $PSBoundParameters.GetEnumerator()){Write-Debug "$($psbp.Key)=$($psbp.Value)"}
    }

    process
    {
        if(Test-Path -Path ENV:\ISHBootstrap_Recipe_Type)
        {
            [pscustomobject]@{
                Type=Get-Item -Path ENV:\ISHBootstrap_Recipe_Type|Select-Object -ExpandProperty Value
                Name=Get-Item -Path ENV:\ISHBootstrap_Recipe_Name|Select-Object -ExpandProperty Value
                Version=Get-Item -Path ENV:\ISHBootstrap_Recipe_Version|Select-Object -ExpandProperty Value|ConvertTo-SemVer
            }
        }
        else
        {
            Write-Warning "Recipe Context is not set because either no recipe was set or the cmdlet is invoked ourside of the execution context of Invoke-CodeDeployHook"
        }
    }

    end
    {

    }
}
