. $PSScriptRoot\Get-ISHServerFolderPath.ps1

function Install-ISHToolJavaHelp 
{
    # http://docs.sdl.com/LiveContent/content/en-US/SDL%20Knowledge%20Center%20full%20documentation-v2/GUID-48FBD1F6-1492-4156-827C-30CA45FC60E9
    $fileName="javahelp-2_0_05.zip"
    $filePath=Join-Path (Get-ISHServerFolderPath) $fileName
    $targetPath="C:\JavaHelp\"
    if(Test-Path $targetPath)
    {
        Write-Warning "$fileName is already installed in $targetPath"
        return
    }
    Write-Debug "Creating $targetPath"
    New-Item $targetPath -ItemType Directory |Out-Null
    Write-Debug "Unzipping $filePath to $targetPath"
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')|Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($filePath, $targetPath)|Out-Null
    Write-Verbose "Installed $filePath"
}