$ec2LaunchPath = Join-Path (Get-Item Env:\ProgramData).Value "Amazon\EC2-Windows\Launch\Config"

$ec2LaunchConfigFile = Join-Path $ec2LaunchPath "LaunchConfig.json"
$ec2EventLogConfigFile = Join-Path $ec2LaunchPath "EventLogConfig.json"
$ec2DriveLetterMappingConfigFile = Join-Path $ec2LaunchPath "DriveLetterMappingConfig.json"

$config = Get-Content -Path $ec2LaunchConfigFile -Raw|ConvertFrom-Json

$config.setComputerName=$true

$config|ConvertTo-Json|Out-File -FilePath $ec2LaunchConfigFile -Force

& $env:ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1 -Schedule