$Script_Name = "Restore WindowsInitialize"
$Script_Author = "Thalix8"
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

# About WindowsApps
Write-Host (Format-CenterText -Text "Start Optimize Windows Apps")


# About WindowsDevice
Write-Host (Format-CenterText -Text "Start Optimize Windows Devices")
powercfg -h on
Set-NetFirewallProfile -Enabled True
Enable-MMAgent -PageCombining
Enable-MMAgent -MemoryCompression
Disable-MMAgent -ApplicationPreLaunch
Set-MMAgent -MaxOperationAPIFiles 256
DISM.exe /Online /Set-ReservedStorageState /State:Enabled
bcdedit /deletevalue useplatformclock
bcdedit /deletevalue useplatformtick
bcdedit /deletevalue disabledynamictic
netsh winsock reset
netsh int ip reset
netsh winsock reset

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
    "SEMgrSvc",
    "wisvc",
    "SDRSVC"

)
foreach ($svc in $Services) {
    try {
        Stop-Service -Name $svc -Force  -ErrorAction Stop
        Set-Service -Name $svc -StartupType Enabled-ErrorAction Stop
    }
    catch {
        Write-Host "[Error] Fail: $($svc) - $_" -ForegroundColor Red
    }
}

# About WindowsCapabilities
Write-Host (Format-CenterText -Text "Start Optimize Windows Regedit")
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v PaintDesktopVersion /t REG_DWORD /d 0 /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\MobilityCenter" /v NoMobilityCenter /t REG_DWORD /d 1 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SgrmBroker" /v Start /t REG_DWORD /d 2 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SgrmBroker" /v DelayedAutoStart /t REG_DWORD /d 2 /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\MTR" /v DontOfferThroughWUAU /t REG_DWORD /d 1 /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v .gif /t REG_SZ /d PhotoViewer.FileAssoc.Tiff /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v .png /t REG_SZ /d PhotoViewer.FileAssoc.Tiff /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v .jpg /t REG_SZ /d PhotoViewer.FileAssoc.Tiff /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v .jpeg /t REG_SZ /d PhotoViewer.FileAssoc.Tiff /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" /v .bmp /t REG_SZ /d PhotoViewer.FileAssoc.Tiff /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 2 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableLastAccessUpdate /t REG_DWORD /d 0 /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 0 /f



Write-Host (Format-CenterText -Text "!!!The End!!!")
Write-Host (Format-CenterText -Text $Script_Name) -ForegroundColor Red
Write-Host (Format-CenterText -Text "Author:",$Script_Author) -ForegroundColor Green

pause

