<#
# Copyright (c) 2021 All Rights Reserved by the SDL Group.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#>

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
