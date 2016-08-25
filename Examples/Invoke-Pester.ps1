param(
    [Parameter(Mandatory=$false)]
    [switch]$Server=$false,
    [Parameter(Mandatory=$false)]
    [switch]$Deployment=$false,
    [Parameter(Mandatory=$false)]
    [switch]$Separate=$false
)
if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$cmdletsPaths="$sourcePath\Cmdlets"
$scriptsPaths="$sourcePath\Scripts"



try
{

    . "$PSScriptRoot\Cmdlets\Get-ISHBootstrapperContextValue.ps1"
    $computerName=Get-ISHBootstrapperContextValue -ValuePath "ComputerName" -DefaultValue $null

    . "$cmdletsPaths\Helpers\Invoke-CommandWrap.ps1"
    if(-not $computerName)
    {
        & "$scriptsPaths\Helpers\Test-Administrator.ps1"
    }
    else
    {
        $session=New-PSSession $computerName
        Invoke-CommandWrap -Session $session -BlockName "Initialize Debug/Verbose preference on $($Session.ComputerName)" -ScriptBlock {}
    }

    $ishDeployments=Get-ISHBootstrapperContextValue -ValuePath "ISHDeployment"
    $ishVersion=Get-ISHBootstrapperContextValue -ValuePath "ISHVersion"
    $folderPath=Get-ISHBootstrapperContextValue -ValuePath "FolderPath"

    function InvokePester ([string]$deploymentName, [string[]]$pesterScripts)
    {
        $parameters=@{
            "ISHVersion" = $ishVersion
        }
        if($deploymentName)
        {
            $parameters.DeploymentName=$deploymentName
        }
        if($Session)
        {
            $parameters.Session = $session
        }
        $script=@{
            Parameters = $parameters
        }

        if($Separate)
        {
            $pesterScripts| ForEach-Object {
                if(-not (Test-Path $_))
                {
                    Write-Warning "$_ not found. Skipping."
                }
                $script.Path=$_
                Invoke-Pester -Script $script # -PassThru -OutputFormat NUnitXml -OutputFile $outputFile
            }
        }
        else
        {
            $path=Join-Path $env:TEMP "ISHBootstrap"
            if($computerName)
            {
                $path=Join-path $path $computerName
            }
            else
            {
                $path=Join-path $path $env:COMPUTERNAME
            }
            if($DeploymentName)
            {
                $path=Join-path $path $DeploymentName
            }
            else
            {
                $path=Join-path $path "Server"
            }
            $testContainerPath=Join-Path $path (Get-Date -Format "yyyyMMddhhmmss")
            if(Test-Path $testContainerPath)
            {
                Remove-Item $testContainerPath -Recurse -Force
            }
            New-Item -Path $testContainerPath -ItemType Directory |Out-Null
            $i=0
            $pesterScripts| ForEach-Object {
                if(-not (Test-Path $_))
                {
                    Write-Warning "$_ not found. Skipping."
                }
                $sourceFileName=Split-Path -Path $_ -Leaf
                $prefix=$i.ToString("000")
                $targetPath=Join-Path $testContainerPath "$prefix.$sourceFileName"
                Copy-Item -Path $_ -Destination $targetPath
            }
            $script.Path=$testContainerPath
            Invoke-Pester -Script $script # -PassThru -OutputFormat NUnitXml -OutputFile $outputFile
        }


    }



    if($Server)
    {
        $scriptsToExecute=@()
        $pester=Get-ISHBootstrapperContextValue -ValuePath "Pester" -DefaultValue $null
        if((-not $pester) -or ($pester.Count -eq 0))
        {
            Write-Warning "No global test scripts defined."
            continue
        }
        $pester | ForEach-Object {
            $scriptFileName=$_
            $scriptPath=Join-Path $folderPath $scriptFileName
            $scriptsToExecute+=$scriptPath
        }
        InvokePester $null $scriptsToExecute
    }

    if($Deployment)
    {
        foreach($ishDeployment in $ishDeployments)
        {
            $deploymentName=$ishDeployment.Name
            $scriptsToExecute=@()
            if((-not $ishDeployment.Pester) -or ($ishDeployment.Pester.Count -eq 0))
            {
                Write-Warning "No deploymen specific test scripts defined for $deploymentName"
                continue
            }
            $ishDeployment.Pester | ForEach-Object {
                $scriptFileName=$_
                $scriptPath=Join-Path $folderPath $scriptFileName
                $scriptsToExecute+=$scriptPath
            }
            InvokePester $deploymentName $scriptsToExecute
        }
    }

}
finally
{
    if($session)
    {
        $session|Remove-PSSession
    }
}
