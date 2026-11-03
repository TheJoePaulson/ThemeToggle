# GetFolderPath('Desktop') resolves the real Desktop, including OneDrive-redirected desktops
$DesktopPath   = [System.Environment]::GetFolderPath("Desktop")
$ShortcutFile  = Join-Path $DesktopPath "Toggle Theme.lnk"
$ScriptFolder  = if ($PSScriptRoot) { $PSScriptRoot } else { "C:\Scripts" }   # same folder as this script; fallback if code is pasted into a console
$ScriptPath    = Join-Path $ScriptFolder "Toggle-Theme.ps1"
$IconDll       = "$env:SystemRoot\System32\imageres.dll"
# Match Toggle-Theme.ps1: Light mode = 96 (moon, "click to go Dark"), Dark mode = 286 ("click to go Light")
$RegPath       = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$IsDark        = ((Get-ItemProperty -Path $RegPath -Name "SystemUsesLightTheme" -ErrorAction SilentlyContinue).SystemUsesLightTheme -eq 0)
$IconIndex     = if ($IsDark) { 286 } else { 96 }

# Locate pwsh.exe (PS7)
$PwshPath = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (-not $PwshPath) {
    $PwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"
}

Write-Host "Desktop path : $DesktopPath"
Write-Host "Shortcut path: $ShortcutFile"
Write-Host "Script path  : $ScriptPath"
Write-Host "pwsh.exe path: $PwshPath"
Write-Host "Icon         : $IconDll,$IconIndex"

try {
    $WshShell                  = New-Object -ComObject WScript.Shell
    $Shortcut                  = $WshShell.CreateShortcut($ShortcutFile)
    $Shortcut.TargetPath       = $PwshPath
    $Shortcut.Arguments        = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
    $Shortcut.WorkingDirectory = Split-Path $ScriptPath -Parent
    $Shortcut.Description      = "Toggle between Custom-DarkMode and Custom-LightMode"
    $Shortcut.IconLocation     = "$IconDll,$IconIndex"
    $Shortcut.Save()

    Write-Host "SUCCESS: Shortcut created at $ShortcutFile" -ForegroundColor Green
    Write-Host "Targeting: $PwshPath" -ForegroundColor Cyan

} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}