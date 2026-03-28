$Script_Name = "WindowsInitialize"
$Script_Author = "Thalix8"
$Script_Version = "5.22.12"
$Update_Time = "2026.3.29-01:35"
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
function RunCheck {
    If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Start-Process powershell "-File `"$PSCommandPath`"" -Verb runAs
        Exit
    }
    $currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
    $allowedPolicies = @("Unrestricted", "RemoteSigned")
    if ($currentPolicy -in $allowedPolicies) {
        Write-Host (Format-CenterText -Text "Operating strategy:[$currentPolicy], Meets the requirements") -ForegroundColor Green
    }
    else {
        Write-Host (Format-CenterText -Text "Operating strategy:[$currentPolicy], Temporarily trust to continue running?")-ForegroundColor Yellow
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -ErrorAction Stop
        if ($currentPolicy -in $allowedPolicies) {
            Write-Host (Format-CenterText -Text "Operating strategy:[$currentPolicy], Meets the requirements") -ForegroundColor Green
        }
        else {
            Write-Host (Format-CenterText -Text "Operating strategy:[$currentPolicy], ") -ForegroundColor Red
            pause
        }
    }
}

function PowerPlan{
    $scheme = (powercfg /getactivescheme) -replace '.*([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}).*', '$1'
    $settings = @(
        @{ Name = "延迟敏感度提示处理器性能"; DisplayName = "延迟敏感度提示处理器性能" },
        @{ Name = "处理器能源性能首选项策略"; DisplayName = "处理器能源性能首选项策略" }
    )

    $queryOutput = powercfg /query $scheme
    $lines = $queryOutput -split "`r`n"
    $foundSettings = @{}
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        foreach ($setting in $settings) {
            if ($line -match $setting.Name) {
                $subgroup = $null
                for ($j = $i; $j -ge 0; $j--) {
                    if ($lines[$j] -match '子组 GUID: ([a-f0-9-]+)') {
                        $subgroup = $matches[1]
                        break
                    }
                }
                $settingGuid = $null
                for ($j = $i; $j -lt $lines.Count; $j++) {
                    if ($lines[$j] -match '电源设置 GUID: ([a-f0-9-]+)') {
                        $settingGuid = $matches[1]
                        break
                    }
                }
                if ($subgroup -and $settingGuid) {
                    $foundSettings[$setting.Name] = @{
                        Subgroup = $subgroup
                        Setting  = $settingGuid
                    }
                    Write-Host "'$($setting.DisplayName)':$subgroup,$settingGuid" -ForegroundColor Green
                } else {
                    Write-Host (Format-CenterText -Text "Not:" $line,"Please Reset!") -ForegroundColor Yellow
                }
                break
            }
        }
    }
    $anyError = $false
    foreach ($name in $settings.Name) {
        if ($foundSettings.ContainsKey($name)) {
            $subgroup = $foundSettings[$name].Subgroup
            $settingGuid = $foundSettings[$name].Setting
            $result = powercfg /setacvalueindex $scheme $subgroup $settingGuid 0
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Error,Please Reset or check permission" -ForegroundColor Red
                $anyError = $true
            }
        } else {
            $anyError = $true
        }
    }
    powercfg /query $scheme | Select-String -Pattern "延迟敏感度|处理器能源性能首选项策略" -Context 2
}

Write-Host (Format-CenterText -Text $Script_Name) -ForegroundColor Red
Write-Host (Format-CenterText -Text "Author:", $Script_Author) -ForegroundColor Green
Write-Host (Format-CenterText -Text "Version:", $Script_Version) -ForegroundColor Blue
Write-Host (Format-CenterText -Text "Time:", $Update_Time)

RunCheck

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
    $appName = $app -replace '\*', ''
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
bcdedit /set hypervisorlaunchtype off
fsutil behavior set disablelastaccess 1
PowerPlan

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
reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f
reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f
reg add "HKCU\Control Panel\Mouse" /v "SmoothMouseXCurve" /t REG_BINARY /d 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 /f
reg add "HKCU\Control Panel\Mouse" /v "SmoothMouseYCurve" /t REG_BINARY /d 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 /f

Write-Host (Format-CenterText -Text "!!!The End!!!")
Write-Host (Format-CenterText -Text $Script_Name) -ForegroundColor Red
Write-Host (Format-CenterText -Text "Author:", $Script_Author) -ForegroundColor Green
Write-Host (Format-CenterText -Text "Version:", $Script_Version) -ForegroundColor Blue
Write-Host (Format-CenterText -Text "Time:", $Update_Time)
pause