# ─── Browse imageres.dll Icons Visually ──────────────────────────────────────
# Displays a scrollable grid of icons with their index numbers
# Run this in PS7 or PS5 — either works

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Runtime.InteropServices;

public class IconExtractor {
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr ExtractIcon(IntPtr hInst, string lpszExeFileName, int nIconIndex);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool DestroyIcon(IntPtr hIcon);
}
"@

$DllPath   = "$env:SystemRoot\System32\imageres.dll"
$StartIdx  = 0
$EndIdx    = 300   # Scan first 300 icons — adjust if needed
$IconSize  = 48
$PerRow    = 8
$PadX      = 10
$PadY      = 20
$LabelH    = 16

# ─── Build Form ──────────────────────────────────────────────────────────────
$form                  = New-Object System.Windows.Forms.Form
$form.Text             = "imageres.dll Icon Browser — Hover or note index numbers"
$form.Size             = New-Object System.Drawing.Size(560, 700)
$form.StartPosition    = "CenterScreen"
$form.AutoScroll       = $true

$col = 0
$row = 0

for ($i = $StartIdx; $i -le $EndIdx; $i++) {
    $hIcon = [IconExtractor]::ExtractIcon([IntPtr]::Zero, $DllPath, $i)
    if ($hIcon -eq [IntPtr]::Zero) { continue }

    try {
        $icon   = [System.Drawing.Icon]::FromHandle($hIcon)
        $bitmap = $icon.ToBitmap()

        $pb          = New-Object System.Windows.Forms.PictureBox
        $pb.Image    = $bitmap
        $pb.SizeMode = "StretchImage"
        $pb.Size     = New-Object System.Drawing.Size($IconSize, $IconSize)
        $pb.Location = New-Object System.Drawing.Point(
            ($col * ($IconSize + $PadX) + 10),
            ($row * ($IconSize + $PadY + $LabelH) + 10)
        )
        $pb.Tag      = $i

        $lbl           = New-Object System.Windows.Forms.Label
        $lbl.Text      = "[$i]"
        $lbl.Font      = New-Object System.Drawing.Font("Segoe UI", 7)
        $lbl.Size      = New-Object System.Drawing.Size($IconSize, $LabelH)
        $lbl.Location  = New-Object System.Drawing.Point(
            $pb.Location.X,
            ($pb.Location.Y + $IconSize)
        )
        $lbl.TextAlign = "MiddleCenter"

        $form.Controls.Add($pb)
        $form.Controls.Add($lbl)

        $col++
        if ($col -ge $PerRow) { $col = 0; $row++ }

    } finally {
        [IconExtractor]::DestroyIcon($hIcon) | Out-Null
    }
}

$form.ShowDialog() | Out-Null