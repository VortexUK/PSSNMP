<#
    .NOTES
    This script controls how the module/resource is built and deployed

    For full information on how this works see: https://git.uberit.net/GR-WINENG/PowerShellDev
#>

[CmdletBinding()]
Param (
    [String]$ModuleName = 'SNMP', # You must specify the module name you are developing
    [String]$Task = 'BuildAndTest', # BuildAndTest is the default when testing locally, you only need to change this when making changes to PowershellDev
    [String]$BuildNumber = 0, # you should bump the major or minor version instead of this, reserved for jenkins
    [String]$PSDevRelease = 'v1.4' # specify the release fo PowershellDev you want to use, point this to a branch if making changes to PowershellDev
)
$BuildScript = 'PSModule.build.ps1'
Invoke-WebRequest -Uri "https://raw.git.uberit.net/GR-WINENG/PowerShellDev/$PSDevRelease/Scripts/$BuildScript" -OutFile $BuildScript
Import-Module -Name InvokeBuild
InvokeBuild\Invoke-Build -File $BuildScript -Task $Task -ModuleName $ModuleName -BuildNumber $BuildNumber -PSDevRelease $PSDevRelease
