@{
    Type="ISHRecipe"
    Version="1.0.0"

    Author="user@example.com"
    CompanyName="SDL"
    Copyright=""
    Description="Vanilla"

    Scripts=@{
        PreRequisite="Test-PreRequisite.ps1"

        Stop=@{
            BeforeCore="Stop-BeforeCore.ps1"
            AfterCore="Stop-AfterCore.ps1"
        }

        Execute="Invoke-Recipe.ps1"

        DatabaseUpgrade=@{
            BeforeCore="Invoke-DatabaseUpgradeBeforeCore.ps1"
            AfterCore="Invoke-DatabaseUpgradeAfterCore.ps1"
        }

        DatabaseUpdate=@{
            BeforeCore="Invoke-DatabaseUpdateBeforeCore.ps1"
            AfterCore="Invoke-DatabaseUpdateAfterCore.ps1"
        }

        Start=@{
            BeforeCore="Start-BeforeCore.ps1"
            AfterCore="Start-AfterCore.ps1"
        }

        Validate="Test-Validate.ps1"
    }
}
