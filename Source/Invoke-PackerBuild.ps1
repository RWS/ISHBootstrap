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
    [string]$BoxPath="$($env:TEMP)\ISH.$ISHVersion-hyperv-iso.box"
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
            }
            else
            {
                Write-Host "Using Microsoft Windows Server 2012 R2 with SQL Server Express AMI ImageId for region $Region"
                $SourceAMI=(Get-EC2ImageByName -Name WINDOWS_2012R2_SQL_SERVER_EXPRESS_2014 -Region $region).ImageId
                $packerFileName="mssql2014-ish-amazon-ebs.json"
            }
            Write-Host "Building with $SourceAMI image id"
        }
        switch($ISHVersion) {
            '12.0.3'{$productLineVersion="2016 SP3"}
            '12.0.4'{$productLineVersion="2016 SP4"}
            '13.0.0'{$productLineVersion="2018"}
        }

        $packerArgs+=@(
            "-var"
            "product_line_version=$productLineVersion"
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
        )


        $packerFileNameName="ish-HyperV-Vagrant.json"
    }
}

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