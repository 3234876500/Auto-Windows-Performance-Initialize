$Script_Name = "WindowsInitialize"
$Script_Author = "Thalix8"
$Script_Version = "4.11.10"
$End_Time = "2025.11.14-09:47"
function Format-CenterText {
    param(
        [string]$Text
    )
    $consoleWidth = $Host.UI.RawUI.WindowSize.Width
    $textLength = $Text.Length
    if ($textLength -ge $consoleWidth) {
        return $Text
    }
    $totalPadding = $consoleWidth - $textLength
    $leftPadding = [math]::Floor($totalPadding / 2)
    $rightPadding = [math]::Ceiling($totalPadding / 2)
    $leftDash = '-' * $leftPadding
    $rightDash = '-' * $rightPadding
    return "${leftDash}${Text}${rightDash}"
}

If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-File `"$PSCommandPath`"" -Verb runAs
    Exit
}

Write-Host (Format-CenterText -Text $Script_Name) -ForegroundColor Red
Write-Host (Format-CenterText -Text "Author:",$Script_Author) -ForegroundColor Green
Write-Host (Format-CenterText -Text "Version:",$Script_Version) -ForegroundColor Blue
Write-Host (Format-CenterText -Text "Time:",$End_Time)

# About WindowsApps
Write-Host (Format-CenterText -Text "Start Optimize Windows Apps")
$apps = @(
    "Microsoft.YourPhone*",
    "Microsoft.WindowsMaps*",
    "Microsoft.MicrosoftStickyNotes*",
    "Microsoft.WindowsFeedbackHub*",
    "Microsoft.People*",
    "Microsoft.ZuneVideo*",
    "*Windows.DevHome*",

    "Microsoft.549981C3F5F10*",
    "Microsoft.Office.OneNote*",
    "Microsoft.Windows.Photos*",
    "Microsoft.MixedReality.Portal*",
    "Microsoft.MicrosoftOfficeHub*",
    "Microsoft.SkypeApp*",

    "Microsoft.XboxApp*",
    "Microsoft.Xbox.TCUI*",
    "Microsoft.XboxGameOverlay*",
    "Microsoft.XboxGamingOverlay*",
    "Microsoft.XboxGameCallableUI*",
    "Microsoft.XboxIdentityProvider*",
    "Microsoft.XboxSpeechToTextOverlay*",

    "Microsoft.PeopleExperienceHost*",
    "Microsoft.EyeControl*",
    "Microsoft.ParentalControls*",
    "Microsoft.Windows.SmartScreen*",
    "Microsoft.WindowsRetailDemo*",
    "Microsoft.XGpuEjectDialog*",
    "Microsoft.SkypeORTC*"
)
foreach ($app in $apps) {
    Get-AppxPackage -AllUsers $app | Remove-AppxPackage -ErrorAction SilentlyContinue
    $appName = $app -replace '\*',''
    Get-AppxProvisionedPackage -Online | Where-Object DisplayName -Like $appName | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}

# About WindowsDevice
Write-Host (Format-CenterText -Text "Start Optimize Windows Devices")
powercfg -h off
Set-NetFirewallProfile -Enabled False
Disable-MMAgent -PageCombining
Disable-MMAgent -MemoryCompression
Disable-MMAgent -ApplicationPreLaunch
Set-MMAgent -MaxOperationAPIFiles 2048
DISM.exe /Online /Set-ReservedStorageState /State:Disabled
bcdedit /set useplatformtick no
bcdedit /set useplatformclock no
bcdedit /set disabledynamictick yes
bcdedit /set hypervusirlauchtype off
fsutil behavior set disablelastaccess 1

# About WindowsService
Write-Host (Format-CenterText -Text "Start Optimize Windows Services")
$Services = @(
    "BITS",
    "DiagTrack",
    "DoSvc",
    "DPS",
    "ClickToRunSvc",
    "MicrosoftEdgeElevationService",
    "edgeupdate",
    "edgeupdatem",
    "Spooler",
    "PrintNotify",
    "UmRdpService",
    "SysMain",
    "WSearch",
    "MapsBroker",
    "WpcMonSvc",
    "RetailDemo",
    "TroubleshootingSvc",
    "SDRSVC"
    "wisvc",
    "SEMgrSvc"
)
foreach ($svc in $Services) {
    try {
        Stop-Service -Name $svc -Force  -ErrorAction Stop
        Set-Service -Name $svc -StartupType Disabled  -ErrorAction Stop
    }
    catch {
        Write-Host "[Error] Fail: $($svc) - $_" -ForegroundColor Red
    }
}

# About WindowsCapabilities
Write-Host (Format-CenterText -Text "Start Optimize Windows Regedit")
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v PaintDesktopVersion /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SgrmBroker" /v Start /t REG_DWORD /d 3 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SgrmBroker" /v DelayedAutoStart /t REG_DWORD /d 3 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 40 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableLastAccessUpdate /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f


Write-Host (Format-CenterText -Text "!!!The End!!!")
Write-Host (Format-CenterText -Text $Script_Name) -ForegroundColor Red
Write-Host (Format-CenterText -Text "Author:",$Script_Author) -ForegroundColor Green
Write-Host (Format-CenterText -Text "Version:",$Script_Version) -ForegroundColor Blue
Write-Host (Format-CenterText -Text "Time:",$End_Time)

pause
