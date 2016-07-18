# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if (-not $myWindowsPrincipal.IsInRole($adminRole))
{
    Write-Error "The current Windows PowerShell session is not running as Administrator. Start Windows PowerShell by  using the Run as Administrator option, and then try running the script again." -RecommendedAction "Start Windows PowerShell by  using the Run as Administrator option, and then try running the script again." -ErrorAction Stop
}