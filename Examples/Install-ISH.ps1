if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"

. "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
$computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null
$credential=Get-ISHBootstrapperContextValue -ValuePath "CredentialExpression" -Invoke

$ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"

. "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"

$ishDeployments=Get-ISHBootstrapperContextValue -ValuePath "ISHDeployment"
$osUserNetworkCredential=(Get-ISHBootstrapperContextValue -ValuePath "OSUserCredentialExpression" -Invoke).GetNetworkCredential()
if($osUserNetworkCredential.Domain -and ($osUserNetworkCredential.Domain -ne ""))
{
    $osUser=$osUserNetworkCredential.Domain
}
else
{
    $osUser="."
}
$osUser+="\"+$osUserNetworkCredential.UserName
$osPassword=$osUserNetworkCredential.Password

$installBlock= {
    foreach($ishDeployment in $ishDeployments)
    {
        $rootPath="C:\IshCD\$ishVersion"
        Write-Debug "rootPath=$rootPath"
        $cdPath=(Get-ChildItem $rootPath |Where-Object{Test-Path $_.FullName -PathType Container}| Sort-Object FullName -Descending)[0]|Select-Object -ExpandProperty FullName
        Write-Debug "cdPath=$cdPath"

        $hash=@{
            CDPath=$cdPath
            Version=$ishVersion
            OSUser=$osUser
            OSPassword=$osPassword
            ConnectionString=$ishDeployment.ConnectionString
            IsOracle=$ishDeployment.IsOracle
            Name=$ishDeployment.Name
            LucenePort=$ishDeployment.LucenePort
            UseRelativePaths=$ishDeployment.UseRelativePaths
        }
        $inputParameters=New-ISHDeploymentInputParameters @hash
        $fileName="inputparameters-$($ishDeployment.Name).xml"
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
    Invoke-CommandWrap -ComputerName $computerName -Credential $credential -ScriptBlock $installBlock -BlockName "Install ISH" -UseParameters @("ishDeployments","ishVersion","osUser","osPassword")

}
finally
{
}
