$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"
. "$here\Test-Manifest"

$name = 'Name' + (Get-random)
$version = 'Version' + (Get-random)
$author = 'Author' + (Get-random)
$companyName = 'CompanyName' + (Get-random)
$copywrite = 'Copyright' + (Get-random)
$description = 'Description' + (Get-random)
$major = 'Major' + (Get-random)
$minor = 'Minor' + (Get-random)
$build = 'Build' + (Get-random)
$revision = 'Revision' + (Get-random)
$prerequisite = 'PreRequisite' + (Get-random)
$databaseUpgradeBeforeCore = 'DatabaseUpgrade' + (Get-random)
$databaseUpgradeAfterCore = 'DatabaseUpgrade' + (Get-random)
$databaseUpdateBeforeCore = 'DatabaseUpdate' + (Get-random)
$databaseUpdateAfterCore = 'DatabaseUpdate' + (Get-random)
$stopBeforeCore = 'StopBeforeCore' + (Get-random)
$stopAfterCore = 'StopAfterCore' + (Get-random)
$execute = 'Execute' + (Get-random)
$startBeforeCore = 'StartBeforeCore' + (Get-random)
$startAfterCore = 'StartAfterCore' + (Get-random)
$validate = 'Validate' + (Get-random)

$publishName = 'Name' + (Get-random)
$publishVersion = 'Version' + (Get-random)
$publishDate = 'Date' + (Get-random)
$publishEngine = 'Engine' + (Get-random)

function RenderManifest([string]$Type, [boolean]$IncludeMetadata, [boolean]$IncludeAllEvents, [boolean]$IncludePrerequisite) {

    $manifest = @"
@{
    Type="$Type"
    Publish=@{
        Name="$publishName"
        Version="$publishVersion"
        Date="$publishDate"
        Engine="$publishEngine"
    }
"@
    if ($IncludeMetadata) {
        $manifest += @"


    Name="$name"
    Version="$version"
    Author="$author"
    CompanyName="$companyName"
    Copyright="$copywrite"
    Description="$description"
"@
    }


    if ($IncludePrerequisite) {
        $manifest += @"


    Prerequisite=@{
        Version=@{
            Major="$major"
            Minor="$minor"
            Build="$build"
            Revision="$revision"
        }
    }
"@
    }

    if ($IncludeAllEvents) {
        $manifest += @"


    Scripts=@{
        PreRequisite="$prerequisite"

        Stop=@{
            BeforeCore="$stopBeforeCore"
            AfterCore="$stopAfterCore"
        }

        Execute="$execute"

        DatabaseUpgrade=@{
            BeforeCore="$databaseUpgradeBeforeCore"
            AfterCore="$databaseUpgradeAfterCore"
        }

        DatabaseUpdate=@{
            BeforeCore="$databaseUpdateBeforeCore"
            AfterCore="$databaseUpdateAfterCore"
        }

        Start=@{
            BeforeCore="$startBeforeCore"
            AfterCore="$startAfterCore"
        }

        Validate="$validate"
    }
"@
    }

    $manifest += @"

}
"@
    $manifest
}

function verifyPublishMetadata($manifest) {
    $manifest.Publish | Should Not BeNullOrEmpty
    $manifest.Publish.Name | Should BeExactly $publishName
    $manifest.Publish.Version | Should BeExactly $publishVersion
    $manifest.Publish.Date | Should BeExactly $publishDate
    $manifest.Publish.Engine | Should BeExactly $publishEngine
}

Describe "Read-Manifest" {
    BeforeEach {
        $tempPath = [System.IO.Path]::GetTempFileName()
        $fileName = Split-Path -Path $tempPath -Leaf
        $folderPath = Split-Path -Path $tempPath -Parent
    }
    AfterEach {
        Remove-Item -Path $tempPath -Force
    }
    It "Read-Manifest Invalid Metadata+AllEvents" {
        RenderManifest ('Invalid' + (Get-random)) $true $true | Out-File $tempPath

        { Read-Manifest -Path $tempPath } | Should Throw
    }
    It "Read-Manifest Invalid" {
        RenderManifest ('Invalid' + (Get-random)) $false $false $false | Out-File $tempPath

        { Read-Manifest -Path $tempPath } | Should Throw
    }
    It "Read-Manifest ISHRecipe without PublishMetadata" {
        @"
@{
    Type="ISHRecipe"
}
"@ | Out-File $tempPath

        { Read-Manifest -Path $tempPath } | Should Throw
    }
    It "Read-Manifest ISHRecipe Metadata+AllEvents" {

        RenderManifest "ISHRecipe" $true $true $false | Out-File $tempPath

        $manifest = Read-Manifest -Path $tempPath

        $manifest.Type | Should BeExactly "ISHRecipe"

        verifyPublishMetadata $manifest

        $manifest.Name | Should BeExactly $name
        $manifest.Version | Should BeExactly $version
        $manifest.Author | Should BeExactly $author
        $manifest.CompanyName | Should BeExactly $companyName
        $manifest.Copyright | Should BeExactly $copywrite
        $manifest.Description | Should BeExactly $description

        $manifest.PrerequisiteMajor | Should BeExactly $null
        $manifest.PrerequisiteMinor | Should BeExactly $null
        $manifest.PrerequisiteBuild | Should BeExactly $null
        $manifest.PrerequisiteRevision | Should BeExactly $null

        $manifest.PreRequisitePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $prerequisite)
        $manifest.StopBeforeCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $stopBeforeCore)
        $manifest.StopAfterCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $stopAfterCore)
        $manifest.ExecutePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $execute)
        $manifest.DatabaseUpgradeBeforeCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $databaseUpgradeBeforeCore)
        $manifest.DatabaseUpgradeAfterCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $databaseUpgradeAfterCore)
        $manifest.DatabaseUpdateBeforeCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $databaseUpdateBeforeCore)
        $manifest.DatabaseUpdateAfterCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $databaseUpdateAfterCore)
        $manifest.StartBeforeCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $startBeforeCore)
        $manifest.StartAfterCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $startAfterCore)
        $manifest.ValidatePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $validate)


        $manifest.FileName | Should BeExactly $fileName
        $manifest.FilePath | Should BeExactly $tempPath
    }
    It "Read-Manifest ISHRecipe" {
        RenderManifest "ISHRecipe" $false $false $false | Out-File $tempPath

        $manifest = Read-Manifest -Path $tempPath

        $manifest.Type | Should BeExactly "ISHRecipe"

        verifyPublishMetadata $manifest

        $manifest.Name | Should BeExactly $null
        $manifest.Version | Should BeExactly $null
        $manifest.Author | Should BeExactly $null
        $manifest.CompanyName | Should BeExactly $null
        $manifest.Copyright | Should BeExactly $null
        $manifest.Description | Should BeExactly $null

        $manifest.PrerequisiteMajor | Should BeExactly $null
        $manifest.PrerequisiteMinor | Should BeExactly $null
        $manifest.PrerequisiteBuild | Should BeExactly $null
        $manifest.PrerequisiteRevision | Should BeExactly $null

        $manifest.PreRequisitePath | Should BeExactly $null
        $manifest.StopBeforeCorePath | Should BeExactly $null
        $manifest.StopAfterCorePath | Should BeExactly $null
        $manifest.ExecutePath | Should BeExactly $null
        $manifest.DatabaseUpgradeBeforeCorePath | Should BeExactly $null
        $manifest.DatabaseUpgradeAfterCorePath | Should BeExactly $null
        $manifest.DatabaseUpdateBeforeCorePath | Should BeExactly $null
        $manifest.DatabaseUpdateAfterCorePath | Should BeExactly $null
        $manifest.StartBeforeCorePath | Should BeExactly $null
        $manifest.StartAfterCorePath | Should BeExactly $null
        $manifest.ValidatePath | Should BeExactly $null


        $manifest.FileName | Should BeExactly $fileName
        $manifest.FilePath | Should BeExactly $tempPath
    }
    It "Read-Manifest ISHRecipe Metadata+Prerequisite" {
        RenderManifest "ISHRecipe" $true $false $true | Out-File $tempPath

        $manifest = Read-Manifest -Path $tempPath

        $manifest.Type | Should BeExactly "ISHRecipe"

        verifyPublishMetadata $manifest

        $manifest.Name | Should BeExactly $name
        $manifest.Version | Should BeExactly $version
        $manifest.Author | Should BeExactly $author
        $manifest.CompanyName | Should BeExactly $companyName
        $manifest.Copyright | Should BeExactly $copywrite
        $manifest.Description | Should BeExactly $description

        $manifest.PrerequisiteMajor | Should BeExactly $major
        $manifest.PrerequisiteMinor | Should BeExactly $minor
        $manifest.PrerequisiteBuild | Should BeExactly $build
        $manifest.PrerequisiteRevision | Should BeExactly $revision

        $manifest.PreRequisitePath | Should BeExactly $null
        $manifest.StopBeforeCorePath | Should BeExactly $null
        $manifest.StopAfterCorePath | Should BeExactly $null
        $manifest.ExecutePath | Should BeExactly $null
        $manifest.DatabaseUpgradeBeforeCorePath | Should BeExactly $null
        $manifest.DatabaseUpgradeAfterCorePath | Should BeExactly $null
        $manifest.DatabaseUpdateBeforeCorePath | Should BeExactly $null
        $manifest.DatabaseUpdateAfterCorePath | Should BeExactly $null
        $manifest.StartBeforeCorePath | Should BeExactly $null
        $manifest.StartAfterCorePath | Should BeExactly $null
        $manifest.ValidatePath | Should BeExactly $null


        $manifest.FileName | Should BeExactly $fileName
        $manifest.FilePath | Should BeExactly $tempPath
    }
    It "Read-Manifest ISHCoreHotfix Metadata+Prerequisite+AllEvents" {
        RenderManifest "ISHCoreHotfix" $true $true $false | Out-File $tempPath

        $manifest = Read-Manifest -Path $tempPath

        $manifest.Type | Should BeExactly "ISHCoreHotfix"

        verifyPublishMetadata $manifest

        $manifest.Name | Should BeExactly $name
        $manifest.Version | Should BeExactly $version
        $manifest.Author | Should BeExactly $author
        $manifest.CompanyName | Should BeExactly $companyName
        $manifest.Copyright | Should BeExactly $copywrite
        $manifest.Description | Should BeExactly $description

        $manifest.PrerequisiteMajor | Should BeExactly $null
        $manifest.PrerequisiteMinor | Should BeExactly $null
        $manifest.PrerequisiteBuild | Should BeExactly $null
        $manifest.PrerequisiteRevision | Should BeExactly $null

        $manifest.PreRequisitePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $prerequisite)
        $manifest.StopBeforeCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $stopBeforeCore)
        $manifest.StopAfterCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $stopAfterCore)
        $manifest.ExecutePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $execute)
        $manifest.DatabaseUpgradeBeforeCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $databaseUpgradeBeforeCore)
        $manifest.DatabaseUpgradeAfterCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $databaseUpgradeAfterCore)
        $manifest.DatabaseUpdateBeforeCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $databaseUpdateBeforeCore)
        $manifest.DatabaseUpdateAfterCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $databaseUpdateAfterCore)
        $manifest.StartBeforeCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $startBeforeCore)
        $manifest.StartAfterCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $startAfterCore)
        $manifest.ValidatePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $validate)


        $manifest.FileName | Should BeExactly $fileName
        $manifest.FilePath | Should BeExactly $tempPath
    }
    It "Read-Manifest ISHCoreHotfix" {
        RenderManifest "ISHCoreHotfix" $false $false $false | Out-File $tempPath

        $manifest = Read-Manifest -Path $tempPath

        verifyPublishMetadata $manifest

        $manifest.Type | Should BeExactly "ISHCoreHotfix"

        $manifest.Name | Should BeExactly $null
        $manifest.Version | Should BeExactly $null
        $manifest.Author | Should BeExactly $null
        $manifest.CompanyName | Should BeExactly $null
        $manifest.Copyright | Should BeExactly $null
        $manifest.Description | Should BeExactly $null

        $manifest.PrerequisiteMajor | Should BeExactly $null
        $manifest.PrerequisiteMinor | Should BeExactly $null
        $manifest.PrerequisiteBuild | Should BeExactly $null
        $manifest.PrerequisiteRevision | Should BeExactly $null

        $manifest.PreRequisitePath | Should BeExactly $null
        $manifest.StopBeforeCorePath | Should BeExactly $null
        $manifest.StopAfterCorePath | Should BeExactly $null
        $manifest.ExecutePath | Should BeExactly $null
        $manifest.DatabaseUpgradeBeforeCorePath | Should BeExactly $null
        $manifest.DatabaseUpgradeAfterCorePath | Should BeExactly $null
        $manifest.DatabaseUpdateBeforeCorePath | Should BeExactly $null
        $manifest.DatabaseUpdateAfterCorePath | Should BeExactly $null
        $manifest.StartBeforeCorePath | Should BeExactly $null
        $manifest.StartAfterCorePath | Should BeExactly $null
        $manifest.ValidatePath | Should BeExactly $null


        $manifest.FileName | Should BeExactly $fileName
        $manifest.FilePath | Should BeExactly $tempPath
    }
    It "Read-Manifest ISHHotfix Metadata+AllEvents" {
        RenderManifest "ISHHotfix" $true $true $false | Out-File $tempPath

        $manifest = Read-Manifest -Path $tempPath

        $manifest.Type | Should BeExactly "ISHHotfix"

        verifyPublishMetadata $manifest

        $manifest.Name | Should BeExactly $name
        $manifest.Version | Should BeExactly $version
        $manifest.Author | Should BeExactly $author
        $manifest.CompanyName | Should BeExactly $companyName
        $manifest.Copyright | Should BeExactly $copywrite
        $manifest.Description | Should BeExactly $description

        $manifest.PrerequisiteMajor | Should BeExactly $null
        $manifest.PrerequisiteMinor | Should BeExactly $null
        $manifest.PrerequisiteBuild | Should BeExactly $null
        $manifest.PrerequisiteRevision | Should BeExactly $null

        $manifest.PreRequisitePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $prerequisite)
        $manifest.StopBeforeCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $stopBeforeCore)
        $manifest.StopAfterCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $stopAfterCore)
        $manifest.ExecutePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $execute)
        $manifest.StartBeforeCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $startBeforeCore)
        $manifest.StartAfterCorePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $startAfterCore)
        $manifest.ValidatePath | Should BeExactly (Join-Path -Path $folderPath -ChildPath $validate)


        $manifest.FileName | Should BeExactly $fileName
        $manifest.FilePath | Should BeExactly $tempPath
    }
    It "Read-Manifest ISHHotfix Metadata" {
        RenderManifest "ISHHotfix" $true $false $false | Out-File $tempPath

        $manifest = Read-Manifest -Path $tempPath

        $manifest.Type | Should BeExactly "ISHHotfix"

        verifyPublishMetadata $manifest

        $manifest.Name | Should BeExactly $name
        $manifest.Version | Should BeExactly $version
        $manifest.Author | Should BeExactly $author
        $manifest.CompanyName | Should BeExactly $companyName
        $manifest.Copyright | Should BeExactly $copywrite
        $manifest.Description | Should BeExactly $description

        $manifest.PrerequisiteMajor | Should BeExactly $null
        $manifest.PrerequisiteMinor | Should BeExactly $null
        $manifest.PrerequisiteBuild | Should BeExactly $null
        $manifest.PrerequisiteRevision | Should BeExactly $null

        $manifest.PreRequisitePath | Should BeExactly $null
        $manifest.StopBeforeCorePath | Should BeExactly $null
        $manifest.StopAfterCorePath | Should BeExactly $null
        $manifest.ExecutePath | Should BeExactly $null
        $manifest.StartBeforeCorePath | Should BeExactly $null
        $manifest.StartAfterCorePath | Should BeExactly $null
        $manifest.ValidatePath | Should BeExactly $null


        $manifest.FileName | Should BeExactly $fileName
        $manifest.FilePath | Should BeExactly $tempPath
    }
}