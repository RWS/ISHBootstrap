param(

)

$cmdletsPaths="$PSScriptRoot\..\..\Cmdlets"

. "$cmdletsPaths\Helpers\Write-Separator.ps1"
Write-Separator -Invocation $MyInvocation -Header

$blockName="[DEVELOPFRIENDLY][Windows Server]:Installing IIS Management Console (inetmgr.exe)"
Write-Host $blockName

Get-WindowsFeature -Name Web-Mgmt-Console|Install-WindowsFeature
    
Write-Warning "[DEVELOPFRIENDLY][Windows Server]:Installed IIS Management Console (inetmgr.exe)"

Write-Separator -Invocation $MyInvocation -Footer
