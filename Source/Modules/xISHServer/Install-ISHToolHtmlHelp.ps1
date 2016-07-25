. $PSScriptRoot\Get-ISHServerFolderPath.ps1

function Install-ISHToolHtmlHelp 
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-7FADBDFC-919D-435F-8E0F-C54A4922100A
    #The original htmlhelp.exe cannot be automated. Extract and create a new zip file.
    $fileName="htmlhelp.zip"
    $filePath=Join-Path (Get-ISHServerFolderPath) $fileName
    $targetPath=Join-Path ${env:ProgramFiles(x86)} "HTML Help Workshop"
    if(Test-Path $targetPath)
    {
        Write-Warning "$fileName is already installed in $targetPath"
        return
    }
    Write-Debug "Creating $targetPath"
    New-Item $targetPath  -ItemType Directory |Out-Null
    Write-Debug "Unzipping $filePath to $targetPath"
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')|Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($filePath, $targetPath)|Out-Null
    Write-Verbose "Installed $filePath"
}