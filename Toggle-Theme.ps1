<#
    .SYNOPSIS
        Toggles between JM-DarkMode and JM-LightMode Windows themes.

    .DESCRIPTION
        Reads the current Windows theme from the registry and applies the
        opposite custom .theme file. Broadcasts a WM_SETTINGCHANGE message
        so the change takes effect immediately. Displays a toast notification
        and swaps the desktop shortcut icon to reflect the active theme.

        Save this script to a stable path (e.g., C:\Scripts\Toggle-JMTheme.ps1)
        Then run the shortcut creation block once to generate the desktop shortcut.

    .NOTES
        Author  : Joe Paulson
        Requires: Windows 10/11
        Themes  : JM-DarkMode.theme / JM-LightMode.theme
                Located in: %LocalAppData%\Microsoft\Windows\Themes
#>

# ─── CONFIG ──────────────────────────────────────────────────────────────────
$ThemesPath    = "$env:LOCALAPPDATA\Microsoft\Windows\Themes"
$DarkTheme     = Join-Path $ThemesPath "JM-DarkMode.theme"
$LightTheme    = Join-Path $ThemesPath "JM-LightMode.theme"
$RegPath       = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$LogFile       = "$env:TEMP\Toggle-JMTheme.log"
#$ShortcutPath  = "$env:USERPROFILE\Desktop\Toggle JM Theme.lnk"
$ShortcutPath  = "C:\Users\paulsonj\OneDrive - Johns Manville\Desktop\Toggle JM Theme.lnk"

# Built-in Windows icons (imageres.dll)
# Index 96  = Moon/Night  → used for Dark Mode (indicates next click = go light)
# Index 234 = Sun/Day     → used for Light Mode (indicates next click = go dark)
$IconDark      = "%SystemRoot%\System32\imageres.dll,96"   # moon icon
$IconLight     = "%SystemRoot%\System32\imageres.dll,234"  # sun icon

# ─── LOGGING ─────────────────────────────────────────────────────────────────
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp  $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# ─── TOAST NOTIFICATION ──────────────────────────────────────────────────────
function Show-ToastNotification {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Emoji = ""
    )

    try {
        Import-Module BurntToast -ErrorAction Stop
        New-BurntToastNotification -Text "$Emoji $Title", "$Message"
        Write-Log "Toast sent: $Title"
    } catch {
        Write-Log "WARNING: Toast notification failed — $($_.Exception.Message)"
    }
}

# ─── BROADCAST SETTINGS CHANGE (immediate apply) ─────────────────────────────
function Send-ThemeChangeMessage {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class WinThemeMsg {
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
        IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
        uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
}
"@ -ErrorAction SilentlyContinue

    $HWND_BROADCAST   = [IntPtr]0xFFFF
    $WM_SETTINGCHANGE = 0x001A
    $SMTO_ABORTIFHUNG = 0x0002
    $result           = [UIntPtr]::Zero

    [WinThemeMsg]::SendMessageTimeout(
        $HWND_BROADCAST,
        $WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        "ImmersiveColorSet",
        $SMTO_ABORTIFHUNG,
        5000,
        [ref]$result
    ) | Out-Null
}

# ─── SHORTCUT ICON SWAP ───────────────────────────────────────────────────────
function Set-ShortcutIcon {
    param(
        [string]$ShortcutPath,
        [string]$IconPath,   # e.g. "C:\Windows\System32\imageres.dll"
        [int]$IconIndex      # e.g. -97
    )

    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.IconLocation = "$IconPath,$IconIndex"
    $Shortcut.Save()

    Write-Log "Shortcut icon updated to: $IconPath,$IconIndex"
}

# ─── VALIDATE THEME FILES EXIST ──────────────────────────────────────────────
Add-Type -AssemblyName System.Windows.Forms

if (-not (Test-Path $DarkTheme)) {
    Write-Log "ERROR: Dark theme file not found: $DarkTheme"
    [System.Windows.Forms.MessageBox]::Show(
        "Dark theme file not found:`n$DarkTheme",
        "Toggle-JMTheme Error", "OK", "Error")
    exit 1
}

if (-not (Test-Path $LightTheme)) {
    Write-Log "ERROR: Light theme file not found: $LightTheme"
    [System.Windows.Forms.MessageBox]::Show(
        "Light theme file not found:`n$LightTheme",
        "Toggle-JMTheme Error", "OK", "Error")
    exit 1
}

if (-not (Test-Path $ShortcutPath)) {
    Write-Log "WARNING: Shortcut not found at expected path: $ShortcutPath — icon swap skipped."
}

# ─── DETECT CURRENT THEME ────────────────────────────────────────────────────
$currentValue    = (Get-ItemProperty -Path $RegPath -Name "SystemUsesLightTheme" `
                        -ErrorAction SilentlyContinue).SystemUsesLightTheme

# 0 = Dark, 1 = Light (or not set = assume Light)
$isCurrentlyDark = ($currentValue -eq 0)

# ─── APPLY OPPOSITE THEME ────────────────────────────────────────────────────
if ($isCurrentlyDark) {
    # ── Switch TO Light ──
    Write-Log "Current: Dark  →  Switching to: JM-LightMode"

    Set-ItemProperty -Path $RegPath -Name "AppsUseLightTheme"    -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $RegPath -Name "SystemUsesLightTheme" -Value 1 -Type DWord -Force

    Send-ThemeChangeMessage

    Start-Process $LightTheme
    Start-Sleep -Seconds 3
    Stop-Process -Name "SystemSettings" -Force -ErrorAction SilentlyContinue

    # Icon swaps to Moon — indicates "click me to go Dark"
    if (Test-Path $ShortcutPath) {
        Set-ShortcutIcon -ShortcutPath $ShortcutPath `
                         -IconPath "$env:SystemRoot\System32\imageres.dll" `
                         -IconIndex 96
    }

    Write-Log "SUCCESS: Applied JM-LightMode"
    Show-ToastNotification -Title "JM Light Mode Applied" `
                           -Message "Your workspace is now in Light Mode." `
                           -Emoji "☀️"

} else {
    # ── Switch TO Dark ──
    Write-Log "Current: Light  →  Switching to: JM-DarkMode"

    Set-ItemProperty -Path $RegPath -Name "AppsUseLightTheme"    -Value 0 -Type DWord -Force
    Set-ItemProperty -Path $RegPath -Name "SystemUsesLightTheme" -Value 0 -Type DWord -Force

    Send-ThemeChangeMessage

    Start-Process $DarkTheme
    Start-Sleep -Seconds 3
    Stop-Process -Name "SystemSettings" -Force -ErrorAction SilentlyContinue

    # Icon swaps to Sun — indicates "click me to go Light"
    if (Test-Path $ShortcutPath) {
        Set-ShortcutIcon -ShortcutPath $ShortcutPath `
                         -IconPath "$env:SystemRoot\System32\imageres.dll" `
                         -IconIndex 286
    }

    Write-Log "SUCCESS: Applied JM-DarkMode"
    Show-ToastNotification -Title "JM Dark Mode Applied" `
                           -Message "Your workspace is now in Dark Mode." `
                           -Emoji "🌙"
}
