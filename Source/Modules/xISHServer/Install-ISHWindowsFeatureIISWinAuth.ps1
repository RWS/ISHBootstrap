function Install-ISHWindowsFeatureIISWinAuth
{
    <#
    ServerManager is expected in Windows Server operating system.
    In a client OS like Windows 7,8 or 10, ServerManager is not available. 
    Instead there is DISM. 
    Server and DISM are much alike but the name of cmdlet, the terms and flow is a bit different.
    With DISM you need to check if a feature is installed before installing it.

    #>
    if(Get-Module ServerManager -ListAvailable)
    {
        $featureNames=@(
            "Web-Windows-Auth"
        )
        Install-WindowsFeature -Name $featureNames |Out-Null
    }
    elseif(Get-Module DISM -ListAvailable)
    {
        Write-Warning "DISM module was found instead of ServerManager. This should happen only in non Server operating systems."
        $features=@(
            "IIS-WindowsAuthentication"
        )

        $notInstalledFeatures=$features|ForEach-Object {
            $feature=Get-WindowsOptionalFeature -FeatureName $_ -Online
            if($feature.State -eq "Enabled")
            {
                Write-Warning "$($feature.FeatureName) is already installed"
            }
            else
            {
                Write-Verbose "$($feature.FeatureName) will be installed"
                $feature
            }
        }
        #$notInstalledFeatures|Format-Table
        $notInstalledFeatures| ForEach-Object {
            try
            {
                $featureName=$_.FeatureName
                Enable-WindowsOptionalFeature -FeatureName $featureName -Online -All
                Write-Host "Enabled feature $featureName"
            }
            catch
            {
                Write-Error "Error for $featureName"
                Write-Error "$_"
            }
        }
    }
    else
    {
        Write-Error "Cannot find ServerManager nor DISM powershell modules installed"
    }
}