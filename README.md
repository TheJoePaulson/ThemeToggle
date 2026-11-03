# Toggle-Theme

![PowerShell](https://img.shields.io/badge/PowerShell-7%2B-5391FE?logo=powershell&logoColor=white)
![Windows 11](https://img.shields.io/badge/Windows-11-0078D4?logo=windows11&logoColor=white)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Maintained](https://img.shields.io/badge/Maintained-yes-brightgreen.svg)

Switch Windows 11 between a **Light** and **Dark** custom theme with one click. The switch applies right away, a toast notification confirms it, and the desktop shortcut icon swaps between a sun and a moon.

---

## Features

- Reads the current mode from the registry and applies the opposite theme
- Changes the Windows and app modes, wallpaper and accent color in one step
- Applies the change immediately (no sign-out needed)
- Optional toast notification (needs the [BurntToast](https://github.com/Windos/BurntToast) module)
- Swaps the desktop shortcut icon to show what the next click will do
- Writes a log to `%TEMP%\Toggle-Theme.log`

## Requirements

| Item | Notes |
|---|---|
| Windows 11 | Windows 10 may work but is untested |
| PowerShell 7+ | The shortcut runs `pwsh.exe` ([install PowerShell 7](https://aka.ms/powershell)) |
| BurntToast module | *Optional.* Only needed for toast notifications |

## Files

| File | Purpose |
|---|---|
| `Toggle-Theme.ps1` | The toggle script |
| `Custom-LightMode.theme` | Light theme with the built-in Bloom wallpaper (`img0.jpg`) |
| `Custom-DarkMode.theme` | Dark theme with the built-in dark Bloom wallpaper (`img19.jpg`) |
| `Create-Shortcut.ps1` | Creates the **Toggle Theme** desktop shortcut (run once) |
| `Icon-Browser.ps1` | Shows the icons in `imageres.dll` with their index numbers |

---

## Installation

**1. Copy the theme files** to your user Themes folder:

```powershell
Copy-Item .\Custom-*.theme "$env:LOCALAPPDATA\Microsoft\Windows\Themes\"
```

**2. Save the scripts** in one folder, for example `C:\Scripts`:

```
C:\Scripts\
├── Toggle-Theme.ps1
├── Create-Shortcut.ps1
└── Icon-Browser.ps1
```

**3. (Optional) Install BurntToast** if you want toast notifications:

```powershell
Install-Module BurntToast -Scope CurrentUser
```

**4. Create the desktop shortcut** by running this once:

```powershell
pwsh -ExecutionPolicy Bypass -File C:\Scripts\Create-Shortcut.ps1
```

This creates **Toggle Theme.lnk** on your desktop (OneDrive-redirected desktops work too). The shortcut runs `Toggle-Theme.ps1` from the same folder, and its starting icon matches your current mode.

> Don't rename the shortcut. `Toggle-Theme.ps1` looks for `Toggle Theme.lnk`, and skips the icon swap if it can't find it.

## Usage

Double-click **Toggle Theme** on your desktop. The script will:

1. Detect whether Windows is in Light or Dark mode
2. Apply the opposite `.theme` file
3. Close the Settings window that Windows opens when a theme is applied
4. Update the shortcut icon and show a toast notification

You can also run it directly:

```powershell
pwsh -ExecutionPolicy Bypass -File C:\Scripts\Toggle-Theme.ps1
```

---

## Customizing the script for your own themes

Everything you need to change is in the **CONFIG** block at the top of `Toggle-Theme.ps1`:

```powershell
$ThemesPath    = "$env:LOCALAPPDATA\Microsoft\Windows\Themes"
$DarkTheme     = Join-Path $ThemesPath "Custom-DarkMode.theme"
$LightTheme    = Join-Path $ThemesPath "Custom-LightMode.theme"
$LogFile       = "$env:TEMP\Toggle-Theme.log"
$ShortcutPath  = Join-Path ([Environment]::GetFolderPath('Desktop')) "Toggle Theme.lnk"
```

| What you want | What to change |
|---|---|
| Use your own theme files | Change the file names in `$DarkTheme` and `$LightTheme` to match your `.theme` files |
| Keep themes in a different folder | Change `$ThemesPath` |
| Use a different shortcut name or location | Change `$ShortcutPath` (the name must match the actual shortcut) |
| Move the log file | Change `$LogFile` |
| Change the toast text | Edit the `-Title` and `-Message` values in the two `Show-ToastNotification` calls |
| Change the shortcut icons | Run `Icon-Browser.ps1` to find index numbers, then edit the `-IconIndex` values (`96` and `286`) in the two `Set-ShortcutIcon` calls in `Toggle-Theme.ps1` **and** the matching values in `Create-Shortcut.ps1` |
| Move the scripts to another folder | Keep all three together, then run `Create-Shortcut.ps1` again from the new folder |

### Creating your own theme file

The easiest way is to use Windows:

1. Go to **Settings > Personalization** and set your wallpaper, colors and Light or Dark mode
2. Go to **Themes > Save** and give the theme a name
3. Windows saves it as a `.theme` file in `%LOCALAPPDATA%\Microsoft\Windows\Themes`. Rename it if needed and point the script at it

You can also edit one of the included `.theme` files in Notepad. The main settings are:

```ini
[Theme]
DisplayName=My Dark Theme                 ; name shown in Settings

[Control Panel\Desktop]
Wallpaper=C:\Path\To\Your\Wallpaper.jpg   ; any image path

[VisualStyles]
ColorizationColor=0XC40078D4              ; accent color (0xAARRGGBB)
AutoColorization=0                        ; 1 = pick accent from wallpaper
SystemMode=Dark                           ; Light or Dark
AppMode=Dark                              ; Light or Dark
```

> **Tip:** Make sure `SystemMode` and `AppMode` match the mode the script expects (Dark in the dark file, Light in the light file). If they don't, the toggle can get out of sync.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| "Theme file not found" pop-up | Check that the `.theme` files are in `$ThemesPath` and the names match exactly |
| Icon doesn't change | Make sure the shortcut name matches `$ShortcutPath` |
| Shortcut does nothing | Check that PowerShell 7 is installed and that `Toggle-Theme.ps1` is in the same folder as `Create-Shortcut.ps1`, then run `Create-Shortcut.ps1` again |
| No toast notification | Install BurntToast, or check the log for a warning |
| Script won't run | Run it with `-ExecutionPolicy Bypass`, or unblock it with `Unblock-File .\Toggle-Theme.ps1` |
| Something else | Check `%TEMP%\Toggle-Theme.log` |

---

## License

This project is licensed under the [MIT License](LICENSE).

```
MIT License

Copyright (c) 2026 Joe Paulson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
