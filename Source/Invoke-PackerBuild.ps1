param(
    [Parameter(Mandatory=$true,ParameterSetName="AWS EC2 AMI")]
    [Parameter(Mandatory=$true,ParameterSetName="Vagrant Hyper-V")]
    [string]$ISHVersion,
    [Parameter(Mandatory=$false,ParameterSetName="AWS EC2 AMI")]
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [string]$MockConnectionString=$null,
    [Parameter(Mandatory=$false,ParameterSetName="AWS EC2 AMI")]
    [string]$SourceAMI,
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
    [Parameter(Mandatory=$true,ParameterSetName="Vagrant Hyper-V")]
    [string]$ISOChecksum,
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [string]$ISOChecksumType="SHA1",
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [string]$SwitchName="External Virtual Switch",
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [string]$BoxPath="$($env:TEMP)\ISH.$ISHVersion-hyperv-iso.box",
    [Parameter(Mandatory=$true,ParameterSetName="Vagrant Hyper-V")]
    [ValidateSet('2012_r2', '2016')]
    [string]$ServerVersion,
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [switch]$NoWindowsUpdates,
    [Parameter(Mandatory=$false,ParameterSetName="Vagrant Hyper-V")]
    [switch]$ServerCore
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
        if(-not $SourceAMI)
        {
            if($MockConnectionString)
            {
                Write-Host "Using Microsoft Windows Server 2016 Base  AMI ImageId for region $Region"
                $SourceAMI=(Get-EC2ImageByName -Name WINDOWS_2016_BASE -Region $region).ImageId
                $packerFileName="ish-amazon-ebs.json"

                $packerArgs+=@(
                    "-var"
                    "ish_mock_connectionstring=$MockConnectionString"
                )
            }
            else
            {
                Write-Host "Using Microsoft Windows Server 2012 R2 with SQL Server Express AMI ImageId for region $Region"
                $SourceAMI=(Get-EC2ImageByName -Name WINDOWS_2012R2_SQL_SERVER_EXPRESS_2014 -Region $region).ImageId
                $packerFileName="mssql2014-ish-amazon-ebs.json"
            }
            Write-Host "Building with $SourceAMI image id"
        }

        $packerArgs+=@(
            "-var"
            "source_ami=$SourceAMI"
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

        $packerFileNameName=$packerFileName
        $logRegExSource="amazon-ebs"
    }
    'Vagrant Hyper-V' {
        $autounattendFilePath="./answer_files/{0}" -f $ServerVersion
        if ($ServerCore.IsPresent)
        {
            $autounattendFilePath="{0}_{1}" -f $autounattendFilePath, "core"
        }
		
        if ($NoWindowsUpdates.IsPresent)
        {
            $autounattendFilePath="{0}_{1}" -f $autounattendFilePath, "no_windows_updates"
        }
	
        $autounattendFilePath="{0}/{1}" -f $autounattendFilePath, "Autounattend.xml"
	
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
            "output_box_path=$BoxPath"
            "-var"
            "autounattend_xml_filepath=$autounattendFilePath"
        )

        if($MockConnectionString)
        {
            Write-Host "No need to install SQL Express"
            $packerArgs+=@(
                "-var"
                "ish_mock_connectionstring=$MockConnectionString"
	    )
        }
        else
        {
            Write-Host "TODO: NEED to install SQL Express"
            Write-Host "The connections string will be calculated."
        }

        $packerFileNameName="ish-HyperV-{0}-Vagrant.json" -f $ServerVersion
    }
}

Write-Host "Using $packerFileNameName"

$packerArgs+=$packerFileNameName

Push-Location -Path "$PSScriptRoot\Packer" -StackName Packer

try
{
    $env:PACKER_LOG=1
    $packetLogPath=Join-Path $env:TEMP "$($packerFileNameName).txt"
    if(Test-Path -Path $packetLogPath)
    {
        Remove-Item -Path $packetLogPath -Force
    }
    $env:PACKER_LOG_PATH=$packetLogPath
    Write-Host "packer $packerArgs"
    & packer $packerArgs
    Write-Host "LASTEXITCODE=$LASTEXITCODE"
}
finally
{
    Write-Warning "Packer log file available in $packetLogPath"
    Pop-Location -StackName Packer

    if($LASTEXITCODE -ne 0)
    {
        if($logRegExSource)
        {
            $packerLogContent=Get-Content -Path  $packetLogPath -Raw
            $regex=".*$($logRegExSource): (?<Objs>\<Objs.*\</Objs\>).*"
            $matchCollections=[regex]::Matches($packerLogContent,$regex)
            if($matchCollections.Count -gt 0)
            {
                Write-Warning "Packer Objs xml entries available:"
                for($i=0;$i -lt $matchCollections.Count;$i++) {
                    $objsItemPath=$packetLogPath.Replace(".txt",".$i.xml")
                    $matchCollections[$i].Groups['Objs'].Value | Format-TidyXml | Out-File -FilePath $objsItemPath
                    Write-Warning $objsItemPath
                }
            }
        }
    }
}
Write-Separator -Invocation $MyInvocation -Footer
