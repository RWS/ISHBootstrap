[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true,ParameterSetName="AWS EC2 AMI")]
    [Parameter(Mandatory=$true,ParameterSetName="Vagrant Hyper-V")]
    [string]$ISHVersion,
    [Parameter(Mandatory=$false,ParameterSetName="AWS EC2 AMI")]
    [Parameter(Mandatory=$true,ParameterSetName="Vagrant Hyper-V")]
    [string]$MockConnectionString=$null,
    [Parameter(Mandatory=$true,ParameterSetName="AWS EC2 AMI")]
    [string]$IAMInstanceProfile,
    [Parameter(Mandatory=$true,ParameterSetName="AWS EC2 AMI")]
    [string]$Region,
    [Parameter(Mandatory=$false,ParameterSetName="AWS EC2 AMI")]
    [Parameter(Mandatory=$true,ParameterSetName="Vagrant Hyper-V")]
    [string]$AccessKey,
    [Parameter(Mandatory=$false,ParameterSetName="AWS EC2 AMI")]
    [Parameter(Mandatory=$true,ParameterSetName="Vagrant Hyper-V")]
    [string]$SecretKey,
    [Parameter(Mandatory=$true,ParameterSetName="Vagrant Hyper-V")]
    [string]$ISOUrl,
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [string]$ISOChecksum=$null,
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [string]$ISOChecksumType="SHA1",
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [string]$SwitchName="External Virtual Switch",
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [ValidateSet('2012_R2', '2016', '2019')]
    [string]$ServerVersion="2016",
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [string]$OutputPath="$env:TEMP",
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [switch]$NoWindowsUpdates=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [switch]$ServerCore=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [switch]$Force=$false
)

if ($PSBoundParameters['Debug']) {
    $DebugPreference = 'Continue'
}

if($PSCmdlet.ParameterSetName -eq "Vagrant Hyper-V")
{
    & $PSScriptRoot\Server\Helpers\Test-Administrator.ps1
}

$cmdletsPaths="$PSScriptRoot\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
. "$cmdletsPaths\Helpers\Format-TidyXml.ps1"
Write-Separator -Invocation $MyInvocation -Header

$packerArgs=@(
    "build"
)

if ($PSBoundParameters['Debug']) {
    $packerArgs+="-debug"
}

$packerArgs+=@(
    "-var"
    "ishVersion=$ISHVersion"
)

switch ($PSCmdlet.ParameterSetName) {
    'AWS EC2 AMI' {
        if($MockConnectionString)
        {
            Write-Host "Using Microsoft Windows Server 2016 Base  AMI ImageId for region $Region"
            $imageName="WINDOWS_2016_BASE"
            $sourceAMI=(Get-EC2ImageByName -Name $imageName -Region $region).ImageId
            $packerFileName="ish-amazon-ebs.json"

            $packerArgs+=@(
                "-var"
                "ish_mock_connectionstring=$MockConnectionString"
            )
        }
        else
        {
            Write-Host "Using Microsoft Windows Server 2012 R2 with SQL Server Express AMI ImageId for region $Region"
            $imageName="WINDOWS_2012R2_SQL_SERVER_EXPRESS_2014"
            $sourceAMI=(Get-EC2ImageByName -Name $imageName -Region $region).ImageId
            $packerFileName="mssql2014-ish-amazon-ebs.json"
        }
        Write-Host "Building with $SourceAMI image id"

        $packerArgs+=@(
            "-var"
            "source_ami=$sourceAMI"
            "-var"
            "iam_instance_profile=$IAMInstanceProfile"
            "-var"
            "region=$Region"
        )

        if($AccessKey)
        {
            $packerArgs+=@(
                "-var"
                "aws_access_key=$AccessKey"
            )
        }
        if($SecretKey)
        {
            $packerArgs+=@(
                "-var"
                "aws_secret_key=$SecretKey"
            )
        }
        $packerFileLocation="AMI\$imageName"

        $logRegExSource="amazon-ebs"
    }
    'Vagrant Hyper-V' {

        if(-not $ISOChecksum)
        {
            $fcivResult = & $PSScriptRoot\Packer\Vagrant\fciv.exe -sha1 $ISOUrl
        
            $ISOChecksum=($fcivResult[3] -split ' ')[0]
            $ISOChecksumType="SHA1"
            Write-Host "$ISOChecksumType checksum is $ISOChecksum"
        }

        $boxNameSegments=@(
            "windowsserver"
            $ServerVersion
            "ish.$ISHVersion"
        )
        $autounattendFolderSegments=@(
            $ServerVersion
        )
        if ($ServerCore)
        {
            $autounattendFolderSegments+="core"
            $boxNameSegments+="core"
        }
		
        if ($NoWindowsUpdates)
        {
            $autounattendFolderSegments+="no_windows_updates"
            $boxNameSegments+="no_windows_updates"
        }
	
        $autounattendFolder=$autounattendFolderSegments -join '_'

        $boxNameSegments+="hyperv"
        $boxName=$boxNameSegments -join '_'
        $boxPath=Join-Path $OutputPath "$($boxName).box"
        if(Test-Path -Path $boxPath)
        {
            if($Force)
            {
                Write-Warning "Removing $boxPath"
            }
            else
            {
                Write-Error "Box $boxPath already exists"
                return 1
            }
        }

        $packerArgs+=@(
            "-var"
            "iso_url=$ISOUrl"
            "-var"
            "iso_checksum_type=$ISOChecksumType"
            "-var"
            "iso_checksum=$ISOChecksum"
            "-var"
            "hyperv_switchname=$SwitchName"
            "-var"
            "aws_access_key=$AccessKey"
            "-var"
            "aws_secret_key=$SecretKey"
            "-var"
            "output_box_path=$boxPath"
            "-var"
            "autounattend_folder=$autounattendFolder"
        )

        if($MockConnectionString)
        {
            $packerArgs+=@(
                "-var"
                "ish_mock_connectionstring=$MockConnectionString"
	        )
        }
        $packerFileLocation="Vagrant\$ServerVersion"

        $packerFileName="ish-$ServerVersion-vagrant-hyperv-iso.json"
        $logRegExSource="hyperv-iso"
    }
}

Write-Host "Using $packerFileName"

$packerArgs+=$packerFileName

$pushPath=Join-Path -Path "$PSScriptRoot\Packer" -ChildPath $packerFileLocation
Push-Location -Path $pushPath -StackName Packer

try
{
    $invokedPacker=$false

    if ($PSCmdlet.ShouldProcess($packerFileName, "packer build")){
        $invokedPacker=$true
        $env:PACKER_LOG=1
        $packerLogPath=Join-Path $env:TEMP "$($packerFileName).$ISHVersion.txt"
        if(Test-Path -Path $packerLogPath)
        {
            Remove-Item -Path $packerLogPath -Force
        }
        $env:PACKER_LOG_PATH=$packerLogPath
        Write-Host "packer $packerArgs"
        & packer $packerArgs
        Write-Host "LASTEXITCODE=$LASTEXITCODE"
    }
    else
    {
        Write-Host "packer $($packerArgs -join ' ')"
    }
}
finally
{
    if($invokedPacker)
    {
        Write-Warning "Packer log file available in $packerLogPath"
        Pop-Location -StackName Packer

        if($LASTEXITCODE -ne 0)
        {
            if($logRegExSource)
            {
                $packerLogContent=Get-Content -Path  $packerLogPath -Raw
                $regex=".*$($logRegExSource): (?<Objs>\<Objs.*\</Objs\>).*"
                $matchCollections=[regex]::Matches($packerLogContent,$regex)
                if($matchCollections.Count -gt 0)
                {
                    Write-Warning "Packer Objs xml entries available:"
                    for($i=0;$i -lt $matchCollections.Count;$i++) {
                        $objsItemPath=$packerLogPath.Replace(".txt",".$i.xml")
                        $matchCollections[$i].Groups['Objs'].Value | Format-TidyXml | Out-File -FilePath $objsItemPath
                        Write-Warning $objsItemPath
                    }
                }
            }
        }
    }
}
Write-Separator -Invocation $MyInvocation -Footer
