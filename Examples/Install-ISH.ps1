if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName"

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$xISHInstallRepository=Get-ISHBootstrapperContextValue -ValuePath "xISHInstallRepository"

$ishDeployments=Get-ISHBootstrapperContextValue -ValuePath "ISHDeployment"
$osUserNetworkCredential=(Invoke-Expression (Get-ISHBootstrapperContextValue -ValuePath "OSUserCredentialExpression")).GetNetworkCredential();
if($osUserNetworkCredential.Domain -and ($osUserNetworkCredential.Domain -ne ""))
{
    $osUser=$osUserNetworkCredential.Domain+"\"+$osUserNetworkCredential.UserName
}
else
{
    $osUser=$osUserNetworkCredential.UserName
}
$osPassword=$osUserNetworkCredential.Password

$installBlock= {
    foreach($ishDeployment in $ishDeployments)
    {
        $rootPath="C:\IshCD\$($ishDeployment.Version)"
        Write-Debug "rootPath=$rootPath"
        $cdPath=(Get-ChildItem $rootPath |Where-Object{Test-Path $_.FullName -PathType Container}| Sort-Object FullName -Descending)[0]|Select-Object -ExpandProperty FullName
        Write-Debug "cdPath=$cdPath"

        $hash=@{
            CDPath=$cdPath
            Version=$ishDeployment.Version
            OSUser=$osUser
            OSPassword=$osPassword
            ConnectionString=$ishDeployment.ConnectionString
            IsOracle=$ishDeployment.IsOracle
            Suffix=$ishDeployment.Suffix
            LucenePort=$ishDeployment.LucenePort
            UseRelativePaths=$ishDeployment.UseRelativePaths
        }
        $inputParameters=New-ISHDeploymentInputParameters @hash
        $fileName="inputparameters-$($ishDeployment.Suffix).xml"
        $filePath=Join-Path $rootPath $fileName
        Write-Debug "filePath=$filePath"
        $inputParameters|Out-File $filePath
        Write-Verbose "Saved to $filePath"
        While(-not (Test-Path $filePath))
        {
            Write-Warning "Test path $filePath failed. Sleeping"
            Start-Sleep -Milliseconds 500
        }

        Write-Debug "Installing from $cdPath with $filePath"
        Install-ISHDeployment -CDPath $cdPath -InputParametersPath $filePath
        Write-Verbose "Installed from $cdPath with $filePath"
    }
}

try
{

    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }
    & $scriptsPaths\PowerShellGet\Install-Module.ps1 -Computer $computerName -ModuleName @("xISHInstall") -Repository $xISHInstallRepository

    Invoke-CommandWrap -ComputerName $computerName -ScriptBlock $installBlock -BlockName "Install ISH" -UseParameters @("ishDeployments","osUser","osPassword")

}
finally
{
}
