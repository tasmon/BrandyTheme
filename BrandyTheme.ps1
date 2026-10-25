#Requires -Version 5.1
<#
.SYNOPSIS
    BrandyTheme - apply branded wallpapers, lock screens, accent colours and icon sets
    on Windows 10 and Windows 11.

.DESCRIPTION
    Brands: HP, Lenovo, Samsung, Intel, AMD, Ryzen.
    Everything is generated locally (gradients + wordmarks + drawn icon sets), so no
    third-party logo files are bundled. To use official logos you are licensed to use,
    drop <Brand>.png into  C:\ProgramData\BrandyTheme\Logos  (e.g. HP.png).

.NOTES
    Author  : Tasmon Islam <tasmon@outlook.com>
    Updates : GitHub Releases at github.com/tasmon/BrandyTheme

.PARAMETER NoUpdateCheck
    Skip the automatic update check at start-up.
.PARAMETER ExportAppIcon
    (Used by the installer) Write BrandyTheme.ico to ProgramData and exit.
.PARAMETER RestoreDefaults
    (Used by the uninstaller) Revert every change BrandyTheme made, without showing the GUI.
#>
[CmdletBinding()]
param(
    [switch]$NoUpdateCheck,
    [switch]$ExportAppIcon,
    [switch]$RestoreDefaults
)

$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------ metadata
$script:AppName     = 'BrandyTheme'
$script:AppVersion  = '1.0.0'
$script:Author      = 'Tasmon Islam'
$script:Email       = 'tasmon@outlook.com'
$script:GitHubOwner = 'tasmon'
$script:GitHubRepo  = 'BrandyTheme'          # <- change if your repository has another name
$script:GitHubUrl   = "https://github.com/$($script:GitHubOwner)/$($script:GitHubRepo)"

$script:AppRoot = $PSScriptRoot
if (-not $script:AppRoot) { $script:AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$script:DataDir      = Join-Path $env:ProgramData 'BrandyTheme'
$script:LogoDir      = Join-Path $script:DataDir 'Logos'
$script:StatePath    = Join-Path $script:DataDir 'state.json'
$script:SettingsPath = Join-Path $script:DataDir 'settings.json'
$script:txtLog       = $null

foreach ($d in @($script:DataDir, $script:LogoDir)) {
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ------------------------------------------------------------------ brands
$script:Brands = @(
    [pscustomobject]@{ Name = 'HP';      Text = 'hp';      Primary = '#0096D6'; Dark = '#00263E' }
    [pscustomobject]@{ Name = 'Lenovo';  Text = 'Lenovo';  Primary = '#E2231A'; Dark = '#1B1B1B' }
    [pscustomobject]@{ Name = 'Samsung'; Text = 'SAMSUNG'; Primary = '#1428A0'; Dark = '#050B33' }
    [pscustomobject]@{ Name = 'Intel';   Text = 'intel';   Primary = '#0071C5'; Dark = '#00162E' }
    [pscustomobject]@{ Name = 'AMD';     Text = 'AMD';     Primary = '#ED1C24'; Dark = '#0D0D0D' }
    [pscustomobject]@{ Name = 'Ryzen';   Text = 'RYZEN';   Primary = '#F26B21'; Dark = '#1A0D05' }
)

# ------------------------------------------------------------------ drawing helpers
function ConvertTo-Color([string]$Hex) { [System.Drawing.ColorTranslator]::FromHtml($Hex) }

function Get-Mix([System.Drawing.Color]$A, [System.Drawing.Color]$B, [double]$T) {
    [System.Drawing.Color]::FromArgb(255,
        [int]($A.R + ($B.R - $A.R) * $T),
        [int]($A.G + ($B.G - $A.G) * $T),
        [int]($A.B + ($B.B - $A.B) * $T))
}

function New-SolidBrush($Color) { New-Object System.Drawing.SolidBrush $Color }

function New-RoundRect([single]$X, [single]$Y, [single]$W, [single]$H, [single]$R) {
    $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $R * 2
    $gp.AddArc($X, $Y, $d, $d, 180, 90)
    $gp.AddArc($X + $W - $d, $Y, $d, $d, 270, 90)
    $gp.AddArc($X + $W - $d, $Y + $H - $d, $d, $d, 0, 90)
    $gp.AddArc($X, $Y + $H - $d, $d, $d, 90, 90)
    $gp.CloseFigure()
    $gp
}

function New-Pts([double[]]$V) {
    $l = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
    for ($i = 0; $i -lt $V.Count; $i += 2) { $l.Add([System.Drawing.PointF]::new([single]$V[$i], [single]$V[$i + 1])) }
    , $l.ToArray()
}

function Find-BrandLogo($Brand) {
    foreach ($dir in @($script:LogoDir, (Join-Path $script:AppRoot 'logos'))) {
        $f = Join-Path $dir ($Brand.Name + '.png')
        if (Test-Path -LiteralPath $f) { return $f }
    }
    $null
}

# Wallpaper / lock-screen artwork
function New-BrandBitmap {
    param($Brand, [int]$Width, [int]$Height, [string]$Mode = 'Wallpaper')
    $bmp = New-Object System.Drawing.Bitmap($Width, $Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.SmoothingMode = 'AntiAlias'
        $g.TextRenderingHint = 'AntiAliasGridFit'
        $g.InterpolationMode = 'HighQualityBicubic'
        $primary = ConvertTo-Color $Brand.Primary
        $dark    = ConvertTo-Color $Brand.Dark

        $rect = New-Object System.Drawing.Rectangle(0, 0, $Width, $Height)
        $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $dark, $primary, 40.0)
        $g.FillRectangle($grad, $rect)
        $grad.Dispose()

        # soft translucent circles
        foreach ($s in @(@(0.88, 0.15, 0.55, 26), @(1.02, 0.95, 0.80, 20), @(0.05, 1.05, 0.45, 22), @(0.55, -0.25, 0.40, 14))) {
            $r = $Height * $s[2]
            $b = New-SolidBrush ([System.Drawing.Color]::FromArgb([int]$s[3], 255, 255, 255))
            $g.FillEllipse($b, [single]($Width * $s[0] - $r), [single]($Height * $s[1] - $r), [single]($r * 2), [single]($r * 2))
            $b.Dispose()
        }
        # diagonal stripe
        $stripe = New-SolidBrush ([System.Drawing.Color]::FromArgb(38, 255, 255, 255))
        $g.FillPolygon($stripe, (New-Pts 0, ($Height * 0.80), $Width, ($Height * 0.52), $Width, ($Height * 0.58), 0, ($Height * 0.86)))
        $stripe.Dispose()

        # wordmark or user-supplied logo
        $logoFile = Find-BrandLogo $Brand
        $margin = $Width * 0.05
        if ($logoFile) {
            $img = [System.Drawing.Image]::FromFile($logoFile)
            try {
                $lh = $Height * 0.14
                $lw = $img.Width * ($lh / $img.Height)
                if ($Mode -eq 'Lock') { $x = ($Width - $lw) / 2; $y = $Height * 0.34 } else { $x = $margin; $y = $Height - $margin - $lh }
                $g.DrawImage($img, [single]$x, [single]$y, [single]$lw, [single]$lh)
            } finally { $img.Dispose() }
        } else {
            $font = New-Object System.Drawing.Font('Segoe UI', [single]($Height * 0.11), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
            $size = $g.MeasureString($Brand.Text, $font)
            if ($Mode -eq 'Lock') { $x = ($Width - $size.Width) / 2; $y = $Height * 0.34 } else { $x = $margin; $y = $Height - $margin - $size.Height }
            $tb = New-SolidBrush ([System.Drawing.Color]::FromArgb(235, 255, 255, 255))
            $g.DrawString($Brand.Text, $font, $tb, [single]$x, [single]$y)
            $tb.Dispose(); $font.Dispose()
        }
        return $bmp
    } finally { $g.Dispose() }
}

# 256px icon artwork
function New-BrandIconBitmap {
    param([string]$Kind, $Brand, [int]$Size = 256)
    $bmp = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.ScaleTransform($Size / 256.0, $Size / 256.0)

    $p     = ConvertTo-Color $Brand.Primary
    $light = Get-Mix $p ([System.Drawing.Color]::White) 0.35
    $deep  = Get-Mix $p ([System.Drawing.Color]::Black) 0.35
    $paper = [System.Drawing.Color]::FromArgb(255, 245, 247, 250)
    $grey  = [System.Drawing.Color]::FromArgb(255, 190, 197, 205)
    $slate = [System.Drawing.Color]::FromArgb(255, 62, 70, 82)
    $glass = [System.Drawing.Color]::FromArgb(70, 255, 255, 255)
    $PF = [System.Drawing.PointF]

    switch ($Kind) {
        'Folder' {
            $g.FillPath((New-SolidBrush $deep), (New-RoundRect 20 46 112 56 12))
            $gb = New-Object System.Drawing.Drawing2D.LinearGradientBrush($PF::new(0, 80), $PF::new(0, 236), $light, $p)
            $g.FillPath($gb, (New-RoundRect 16 80 224 156 18))
            $g.FillRectangle((New-SolidBrush $glass), 28, 92, 200, 5)
        }
        'FolderOpen' {
            $g.FillPath((New-SolidBrush $deep), (New-RoundRect 16 50 224 150 16))
            $g.FillPath((New-SolidBrush $paper), (New-RoundRect 40 66 176 110 6))
            $gb = New-Object System.Drawing.Drawing2D.LinearGradientBrush($PF::new(0, 110), $PF::new(0, 236), $light, $p)
            $g.FillPolygon($gb, (New-Pts 6, 236, 40, 112, 250, 112, 218, 236))
        }
        'File' {
            $page = New-Pts 56, 20, 152, 20, 208, 76, 208, 236, 56, 236
            $g.FillPolygon((New-SolidBrush $paper), $page)
            $g.FillPolygon((New-SolidBrush $grey), (New-Pts 152, 20, 152, 76, 208, 76))
            $g.FillRectangle((New-SolidBrush $p), 56, 170, 152, 66)
            foreach ($row in @(@(100, 90), @(124, 112), @(148, 100))) { $g.FillRectangle((New-SolidBrush $grey), 76, $row[0], $row[1], 8) }
            $g.DrawPolygon((New-Object System.Drawing.Pen($grey, 4)), $page)
        }
        'App' {
            $g.FillPath((New-SolidBrush $p), (New-RoundRect 22 40 212 176 16))
            $g.FillPath((New-SolidBrush $paper), (New-RoundRect 32 82 192 124 8))
            foreach ($x in 44, 66, 88) { $g.FillEllipse((New-SolidBrush $paper), $x, 54, 14, 14) }
            $g.FillRectangle((New-SolidBrush $light), 50, 104, 90, 12)
            $g.FillRectangle((New-SolidBrush $grey), 50, 128, 140, 10)
            $g.FillRectangle((New-SolidBrush $grey), 50, 150, 120, 10)
        }
        'Drive' {
            $gb = New-Object System.Drawing.Drawing2D.LinearGradientBrush($PF::new(0, 96), $PF::new(0, 192), $paper, $grey)
            $g.FillPath($gb, (New-RoundRect 12 96 232 96 20))
            $g.DrawPath((New-Object System.Drawing.Pen($slate, 5)), (New-RoundRect 12 96 232 96 20))
            $g.FillRectangle((New-SolidBrush $slate), 36, 128, 120, 8)
            $g.FillRectangle((New-SolidBrush $slate), 36, 148, 80, 8)
            $g.FillEllipse((New-SolidBrush $p), 196, 130, 22, 22)
        }
        'Disc' {
            $g.FillEllipse((New-SolidBrush ([System.Drawing.Color]::FromArgb(255, 226, 231, 237))), 20, 20, 216, 216)
            $g.FillEllipse((New-SolidBrush $p), 54, 54, 148, 148)
            $g.FillEllipse((New-SolidBrush ([System.Drawing.Color]::FromArgb(255, 226, 231, 237))), 90, 90, 76, 76)
            $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $g.FillEllipse((New-SolidBrush ([System.Drawing.Color]::Transparent)), 112, 112, 32, 32)
            $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
        }
        'Pc' {
            $g.FillPath((New-SolidBrush $slate), (New-RoundRect 22 36 212 146 16))
            $sg = New-Object System.Drawing.Drawing2D.LinearGradientBrush($PF::new(0, 50), $PF::new(0, 168), $light, $deep)
            $g.FillRectangle($sg, 36, 50, 184, 118)
            $g.FillPolygon((New-SolidBrush $glass), (New-Pts 36, 50, 150, 50, 90, 168, 36, 168))
            $g.FillRectangle((New-SolidBrush $slate), 112, 182, 32, 26)
            $g.FillPath((New-SolidBrush $slate), (New-RoundRect 72 206 112 18 8))
        }
        { $_ -in 'Recycle', 'RecycleFull' } {
            if ($Kind -eq 'RecycleFull') {
                $g.FillPolygon((New-SolidBrush $paper), (New-Pts 78, 52, 118, 30, 134, 62, 94, 78))
                $g.FillPolygon((New-SolidBrush $grey),  (New-Pts 124, 34, 168, 40, 160, 76, 120, 70))
            }
            $g.FillPath((New-SolidBrush $deep), (New-RoundRect 100 34 56 24 8))
            $g.FillPolygon((New-SolidBrush $p), (New-Pts 64, 88, 192, 88, 174, 238, 82, 238))
            $g.FillPath((New-SolidBrush $deep), (New-RoundRect 48 62 160 26 9))
            foreach ($x in 104, 126, 148) { $g.FillRectangle((New-SolidBrush $glass), $x, 106, 7, 112) }
        }
        'Network' {
            $g.FillEllipse((New-SolidBrush $p), 28, 28, 200, 200)
            $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(210, 255, 255, 255), 8)
            $g.DrawEllipse($pen, 78, 28, 100, 200)
            $g.DrawLine($pen, 28, 128, 228, 128)
            $g.DrawLine($pen, 37, 86, 219, 86)
            $g.DrawLine($pen, 37, 170, 219, 170)
        }
        'User' {
            $g.FillEllipse((New-SolidBrush $p), 88, 30, 80, 80)
            $g.FillPie((New-SolidBrush $p), 40, 134, 176, 190, 180, 180)
        }
        'Control' {
            $st = $g.Save()
            $g.TranslateTransform(128, 128)
            for ($i = 0; $i -lt 8; $i++) { $g.RotateTransform(45); $g.FillRectangle((New-SolidBrush $p), -20, -112, 40, 44) }
            $g.FillEllipse((New-SolidBrush $p), -84, -84, 168, 168)
            $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $g.FillEllipse((New-SolidBrush ([System.Drawing.Color]::Transparent)), -38, -38, 76, 76)
            $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
            $g.Restore($st)
        }
    }
    $g.Dispose()
    $bmp
}

function New-AppIconBitmap([int]$Size = 256) {
    $bmp = New-Object System.Drawing.Bitmap($Size, $Size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.ScaleTransform($Size / 256.0, $Size / 256.0)
    $gb = New-Object System.Drawing.Drawing2D.LinearGradientBrush([System.Drawing.PointF]::new(0, 0), [System.Drawing.PointF]::new(256, 256),
        (ConvertTo-Color '#0071C5'), (ConvertTo-Color '#F26B21'))
    $g.FillPath($gb, (New-RoundRect 8 8 240 240 52))
    $font = New-Object System.Drawing.Font('Segoe UI', 150, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
    $g.DrawString('B', $font, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF(0, 8, 256, 256)), $fmt)
    $g.Dispose()
    $bmp
}

# Writes a multi-size PNG-compressed .ico
function Save-Ico($Bitmap, [string]$Path) {
    $sizes = 256, 48, 32, 16
    $pngs = @()
    foreach ($s in $sizes) {
        $b = New-Object System.Drawing.Bitmap($s, $s, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($b)
        $g.InterpolationMode = 'HighQualityBicubic'; $g.SmoothingMode = 'HighQuality'; $g.PixelOffsetMode = 'HighQuality'
        $g.DrawImage($Bitmap, 0, 0, $s, $s)
        $g.Dispose()
        $ms = New-Object System.IO.MemoryStream
        $b.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
        $pngs += , $ms.ToArray()
        $b.Dispose(); $ms.Dispose()
    }
    $fs = [System.IO.File]::Create($Path)
    $bw = New-Object System.IO.BinaryWriter($fs)
    $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$sizes.Count)
    $offset = 6 + 16 * $sizes.Count
    for ($i = 0; $i -lt $sizes.Count; $i++) {
        $dim = if ($sizes[$i] -ge 256) { 0 } else { $sizes[$i] }
        $bw.Write([byte]$dim); $bw.Write([byte]$dim); $bw.Write([byte]0); $bw.Write([byte]0)
        $bw.Write([uint16]1); $bw.Write([uint16]32)
        $bw.Write([uint32]$pngs[$i].Length); $bw.Write([uint32]$offset)
        $offset += $pngs[$i].Length
    }
    foreach ($png in $pngs) { $bw.Write([byte[]]$png) }
    $bw.Close(); $fs.Close()
}

# -------- installer helper mode: export the app icon and quit (no elevation needed)
if ($ExportAppIcon) {
    $bmp = New-AppIconBitmap 256
    Save-Ico $bmp (Join-Path $script:DataDir 'BrandyTheme.ico')
    $bmp.Dispose()
    exit 0
}

# ------------------------------------------------------------------ elevation + STA
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$isSta   = [System.Threading.Thread]::CurrentThread.GetApartmentState() -eq 'STA'
if (-not $isAdmin -or -not $isSta) {
    $argStr = "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
    if ($NoUpdateCheck)   { $argStr += ' -NoUpdateCheck' }
    if ($RestoreDefaults) { $argStr += ' -RestoreDefaults' }
    Start-Process -FilePath powershell.exe -ArgumentList $argStr -Verb RunAs
    exit
}

if ([Environment]::OSVersion.Version.Major -lt 10) {
    [void][System.Windows.Forms.MessageBox]::Show('BrandyTheme requires Windows 10 or Windows 11.', $script:AppName, 'OK', 'Error')
    exit 1
}

if (-not ('BrandyNative' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class BrandyNative {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int action, int param, string value, int flags);
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint msg, UIntPtr wParam, string lParam, uint flags, uint timeout, out UIntPtr result);
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
'@
}
[void][BrandyNative]::SetProcessDPIAware()

# ------------------------------------------------------------------ logging, settings, state
function Write-Log([string]$Message) {
    $line = "[{0:HH:mm:ss}] {1}" -f (Get-Date), $Message
    if ($script:txtLog) { $script:txtLog.AppendText($line + "`r`n"); [System.Windows.Forms.Application]::DoEvents() }
    else { Write-Host $line }
}

function Read-Settings {
    $s = @{ AutoUpdate = $true }
    if (Test-Path -LiteralPath $script:SettingsPath) {
        try { $j = Get-Content -LiteralPath $script:SettingsPath -Raw | ConvertFrom-Json; if ($null -ne $j.AutoUpdate) { $s.AutoUpdate = [bool]$j.AutoUpdate } } catch { }
    }
    $s
}
function Write-Settings { $script:Settings | ConvertTo-Json | Set-Content -LiteralPath $script:SettingsPath -Encoding UTF8 }

function Read-State {
    $s = @{ Registry = @{}; StartFolders = @() }
    if (Test-Path -LiteralPath $script:StatePath) {
        try {
            $j = Get-Content -LiteralPath $script:StatePath -Raw | ConvertFrom-Json
            foreach ($p in $j.Registry.PSObject.Properties) { $s.Registry[$p.Name] = @{ Value = $p.Value.Value; Kind = $p.Value.Kind } }
            $s.StartFolders = @($j.StartFolders | Where-Object { $_ })
        } catch { }
    }
    $s
}
function Write-State { $script:State | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $script:StatePath -Encoding UTF8 }

$script:Settings = Read-Settings
$script:State    = Read-State

# ------------------------------------------------------------------ registry helpers (with backup)
function Save-RegBackup([string]$Path, [string]$Name) {
    $key = "$Path|$Name"
    if ($script:State.Registry.ContainsKey($key)) { return }       # keep the ORIGINAL value only
    $entry = @{ Value = $null; Kind = $null }
    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -LiteralPath $Path
        $real = if ($Name -eq '(default)') { '' } else { $Name }
        if ($item.GetValueNames() -contains $real) {
            $entry.Value = $item.GetValue($real, $null, 'DoNotExpandEnvironmentNames')
            $entry.Kind  = $item.GetValueKind($real).ToString()
        }
    }
    $script:State.Registry[$key] = $entry
}

function Set-Reg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'String')
    Save-RegBackup $Path $Name
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

$script:ClsidMap = [ordered]@{
    '{20D04FE0-3AEA-1069-A2D8-08002B30309D}' = 'Pc'            # This PC
    '{59031a47-3f72-44a7-89c5-5595fe6b30ee}' = 'User'          # User's Files
    '{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}' = 'Network'       # Network
    '{26EE0668-A00A-44D7-9371-BEB064C98683}' = 'Control'       # Control Panel (category view)
    '{21EC2020-3AEA-1069-A2DD-08002B30309D}' = 'Control'       # Control Panel (all items)
    '{645FF040-5081-101B-9F08-00AA002F954E}' = 'Recycle'       # Recycle Bin
}

function Restore-Registry {
    foreach ($k in @($script:State.Registry.Keys)) {
        $path, $name = $k -split '\|', 2
        $entry = $script:State.Registry[$k]
        try {
            if ($null -eq $entry.Kind) {
                if (Test-Path -LiteralPath $path) { Remove-ItemProperty -LiteralPath $path -Name $name -ErrorAction SilentlyContinue }
            } else {
                $val = $entry.Value
                if ($entry.Kind -eq 'Binary') { $val = [byte[]]@($val) }
                if ($entry.Kind -eq 'DWord')  { $val = [int]$val }
                if (-not (Test-Path -LiteralPath $path)) { New-Item -Path $path -Force | Out-Null }
                New-ItemProperty -LiteralPath $path -Name $name -Value $val -PropertyType $entry.Kind -Force | Out-Null
            }
        } catch { Write-Log "Could not restore $k : $($_.Exception.Message)" }
    }
    # remove now-empty per-user CLSID override keys we created
    foreach ($guid in $script:ClsidMap.Keys) {
        $di = "HKCU:\Software\Classes\CLSID\$guid\DefaultIcon"
        $cl = "HKCU:\Software\Classes\CLSID\$guid"
        foreach ($kp in @($di, $cl)) {
            if (Test-Path -LiteralPath $kp) {
                $it = Get-Item -LiteralPath $kp
                if ($it.ValueCount -eq 0 -and $it.SubKeyCount -eq 0) { Remove-Item -LiteralPath $kp -Force -ErrorAction SilentlyContinue }
            }
        }
    }
    $script:State.Registry = @{}
}

# ------------------------------------------------------------------ theme actions
function Update-ShellIcons {
    [BrandyNative]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
    $r = [UIntPtr]::Zero
    [void][BrandyNative]::SendMessageTimeout([IntPtr]0xFFFF, 0x1A, [UIntPtr]::Zero, 'ImmersiveColorSet', 2, 5000, [ref]$r)
    foreach ($a in '-ClearIconCache', '-show') {
        try { Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\ie4uinit.exe') -ArgumentList $a -WindowStyle Hidden -Wait } catch { }
    }
}

function Set-BrandWallpaper($Brand, [int]$W, [int]$H) {
    $dir = Join-Path $script:DataDir 'Generated'
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $file = Join-Path $dir ("{0}-wallpaper-{1:yyyyMMddHHmmss}.png" -f $Brand.Name, (Get-Date))
    $bmp = New-BrandBitmap $Brand $W $H 'Wallpaper'
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    $desk = 'HKCU:\Control Panel\Desktop'
    Set-Reg $desk 'Wallpaper' $file 'String'
    Set-Reg $desk 'WallpaperStyle' '10' 'String'     # Fill
    Set-Reg $desk 'TileWallpaper' '0' 'String'
    [void][BrandyNative]::SystemParametersInfo(20, 0, $file, 3)
    Get-ChildItem -LiteralPath $dir -Filter "$($Brand.Name)-wallpaper-*.png" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 3 |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

function Set-BrandLockScreen($Brand, [int]$W, [int]$H) {
    $dir = Join-Path $script:DataDir 'Lock'
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $file = Join-Path $dir ("{0}-lock-{1:yyyyMMddHHmmss}.png" -f $Brand.Name, (Get-Date))
    $bmp = New-BrandBitmap $Brand $W $H 'Lock'
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    $csp = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
    Set-Reg $csp 'LockScreenImagePath'   $file 'String'
    Set-Reg $csp 'LockScreenImageUrl'    $file 'String'
    Set-Reg $csp 'LockScreenImageStatus' 1     'DWord'
    Get-ChildItem -LiteralPath $dir -Filter "$($Brand.Name)-lock-*.png" | Sort-Object LastWriteTime -Descending | Select-Object -Skip 3 |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

function Set-BrandAccent($Brand, [bool]$Dark) {
    $c = ConvertTo-Color $Brand.Primary
    $abgr = ([int]-16777216) -bor ([int]$c.B -shl 16) -bor ([int]$c.G -shl 8) -bor [int]$c.R
    $argb = ([int]-16777216) -bor ([int]$c.R -shl 16) -bor ([int]$c.G -shl 8) -bor [int]$c.B
    $white = [System.Drawing.Color]::White; $black = [System.Drawing.Color]::Black
    $shades = @((Get-Mix $c $white 0.6), (Get-Mix $c $white 0.4), (Get-Mix $c $white 0.2), $c,
                (Get-Mix $c $black 0.2), (Get-Mix $c $black 0.4), (Get-Mix $c $black 0.6))
    $pal = New-Object byte[] 32
    for ($i = 0; $i -lt 7; $i++) { $pal[$i * 4] = $shades[$i].R; $pal[$i * 4 + 1] = $shades[$i].G; $pal[$i * 4 + 2] = $shades[$i].B; $pal[$i * 4 + 3] = 0 }
    $pal[28] = 0xF7; $pal[29] = 0x63; $pal[30] = 0x0C; $pal[31] = 0

    $dwm = 'HKCU:\Software\Microsoft\Windows\DWM'
    Set-Reg $dwm 'AccentColor' $abgr 'DWord'
    Set-Reg $dwm 'ColorizationColor' $argb 'DWord'
    Set-Reg $dwm 'ColorizationAfterglow' $argb 'DWord'
    Set-Reg $dwm 'ColorPrevalence' 1 'DWord'
    $acc = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'
    Set-Reg $acc 'AccentColorMenu' $abgr 'DWord'
    Set-Reg $acc 'StartColorMenu' $abgr 'DWord'
    Set-Reg $acc 'AccentPalette' $pal 'Binary'
    Set-Reg 'HKCU:\Control Panel\Desktop' 'AutoColorization' 0 'DWord'
    $per = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    Set-Reg $per 'ColorPrevalence' 1 'DWord'
    if ($Dark) {
        Set-Reg $per 'AppsUseLightTheme' 0 'DWord'
        Set-Reg $per 'SystemUsesLightTheme' 0 'DWord'
    }
}

function Set-DarkModeOnly {
    $per = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    Set-Reg $per 'AppsUseLightTheme' 0 'DWord'
    Set-Reg $per 'SystemUsesLightTheme' 0 'DWord'
}

function Build-BrandIcons($Brand) {
    $dir = Join-Path $script:DataDir ("Icons\{0}-v{1}" -f $Brand.Name, $script:AppVersion)
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $set = @{}
    foreach ($kind in 'Folder', 'FolderOpen', 'File', 'App', 'Drive', 'Disc', 'Pc', 'Recycle', 'RecycleFull', 'Network', 'User', 'Control') {
        $path = Join-Path $dir ($kind.ToLower() + '.ico')
        if (-not (Test-Path -LiteralPath $path)) {
            $bmp = New-BrandIconBitmap $kind $Brand 256
            Save-Ico $bmp $path
            $bmp.Dispose()
        }
        $set[$kind] = $path
    }
    $set
}

function Set-ShellIcons($Icons) {
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons'
    $map = @{ '0' = 'File'; '2' = 'App'; '3' = 'Folder'; '4' = 'FolderOpen'; '7' = 'Drive'; '8' = 'Drive'; '11' = 'Disc' }
    foreach ($idx in $map.Keys) { Set-Reg $key $idx ("{0},0" -f $Icons[$map[$idx]]) 'String' }
}

function Set-DesktopIcons($Icons) {
    foreach ($guid in $script:ClsidMap.Keys) {
        $kind = $script:ClsidMap[$guid]
        $key = "HKCU:\Software\Classes\CLSID\$guid\DefaultIcon"
        $val = "{0},0" -f $Icons[$kind]
        Set-Reg $key '(default)' $val 'String'
        if ($kind -eq 'Recycle') {
            Set-Reg $key 'empty' ("{0},0" -f $Icons['Recycle']) 'String'
            Set-Reg $key 'full'  ("{0},0" -f $Icons['RecycleFull']) 'String'
        }
    }
}

function Set-StartFolderIcons($Icons) {
    $roots = @((Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'),
               (Join-Path $env:ProgramData 'Microsoft\Windows\Start Menu\Programs'))
    foreach ($root in $roots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        foreach ($dirInfo in Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue) {
            $ini = Join-Path $dirInfo.FullName 'desktop.ini'
            if ([System.IO.File]::Exists($ini)) { continue }          # never touch existing customisations
            try {
                Set-Content -LiteralPath $ini -Value ("[.ShellClassInfo]`r`nIconResource={0},0`r`n" -f $Icons['Folder']) -Encoding Unicode -Force
                [System.IO.File]::SetAttributes($ini, [System.IO.FileAttributes]'Hidden,System')
                & attrib.exe +s "$($dirInfo.FullName)" | Out-Null
                $script:State.StartFolders += $ini
            } catch { }
        }
    }
}

function Restore-All {
    Write-Log 'Restoring original appearance...'
    Restore-Registry
    foreach ($ini in @($script:State.StartFolders)) {
        if ($ini -and [System.IO.File]::Exists($ini)) {
            try {
                [System.IO.File]::SetAttributes($ini, [System.IO.FileAttributes]::Normal)
                Remove-Item -LiteralPath $ini -Force
                & attrib.exe -s "$(Split-Path -Parent $ini)" | Out-Null
            } catch { }
        }
    }
    $script:State.StartFolders = @()
    $wp = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -ErrorAction SilentlyContinue).Wallpaper
    if ($wp) { [void][BrandyNative]::SystemParametersInfo(20, 0, $wp, 3) }
    Write-State
    Update-ShellIcons
    Write-Log 'Done. Sign out and back in to finish restoring the lock screen and accent colours.'
}

# headless restore (used by the uninstaller)
if ($RestoreDefaults) { Restore-All; exit 0 }

# ------------------------------------------------------------------ auto-update (GitHub Releases)
function ConvertTo-VersionObject([string]$Tag) {
    $t = ($Tag.Trim().TrimStart('v', 'V') -split '[-+]')[0]
    [version]$t
}

function Get-LatestRelease {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = "https://api.github.com/repos/$($script:GitHubOwner)/$($script:GitHubRepo)/releases/latest"
    Invoke-RestMethod -Uri $uri -TimeoutSec 8 -Headers @{ 'User-Agent' = "$($script:AppName)/$($script:AppVersion)"; 'Accept' = 'application/vnd.github+json' }
}

function Install-Update($Release) {
    $zipAsset = $Release.assets | Where-Object { $_.name -like 'BrandyTheme*.zip' } | Select-Object -First 1
    $shaAsset = $Release.assets | Where-Object { $_.name -like 'BrandyTheme*.zip.sha256' } | Select-Object -First 1
    if (-not $zipAsset -or -not $shaAsset) { throw 'The release is missing the .zip or its .sha256 checksum file; update aborted.' }
    $prefix = "https://github.com/$($script:GitHubOwner)/"
    foreach ($a in $zipAsset, $shaAsset) {
        if (-not ($a.browser_download_url -like "$prefix*")) { throw 'Unexpected download location; update aborted.' }
    }
    $ProgressPreference = 'SilentlyContinue'
    $work = Join-Path $env:TEMP ('BrandyThemeUpdate-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    $zip = Join-Path $work $zipAsset.name
    $sha = Join-Path $work $shaAsset.name
    Write-Log "Downloading $($zipAsset.name)..."
    Invoke-WebRequest -Uri $zipAsset.browser_download_url -OutFile $zip -UseBasicParsing -TimeoutSec 120
    Invoke-WebRequest -Uri $shaAsset.browser_download_url -OutFile $sha -UseBasicParsing -TimeoutSec 30
    $expected = ((Get-Content -LiteralPath $sha -Raw).Trim() -split '\s+')[0]
    $actual = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
    if ($expected -ne $actual) { throw 'Checksum mismatch - the download is corrupt or has been tampered with. Update aborted.' }

    $extract = Join-Path $work 'x'
    Expand-Archive -LiteralPath $zip -DestinationPath $extract -Force
    $main = Get-ChildItem -LiteralPath $extract -Recurse -Filter 'BrandyTheme.ps1' | Select-Object -First 1
    if (-not $main) { throw 'The update package does not contain BrandyTheme.ps1.' }
    $src = $main.DirectoryName

    $updater = Join-Path $work 'apply-update.ps1'
    @'
param([int]$ProcId, [string]$Source, [string]$Target)
try { Wait-Process -Id $ProcId -Timeout 60 -ErrorAction SilentlyContinue } catch { }
Start-Sleep -Milliseconds 500
Copy-Item -Path (Join-Path $Source '*') -Destination $Target -Recurse -Force
Get-ChildItem -LiteralPath $Target -Recurse -File | Unblock-File -ErrorAction SilentlyContinue
$m = Select-String -Path (Join-Path $Target 'BrandyTheme.ps1') -Pattern "AppVersion\s*=\s*'([^']+)'" | Select-Object -First 1
if ($m) {
    $k = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\BrandyTheme'
    if (Test-Path $k) { Set-ItemProperty -Path $k -Name DisplayVersion -Value $m.Matches[0].Groups[1].Value }
}
Start-Process powershell.exe -ArgumentList ('-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}"' -f (Join-Path $Target 'BrandyTheme.ps1'))
'@ | Set-Content -LiteralPath $updater -Encoding UTF8

    Write-Log 'Checksum verified. Restarting to apply the update...'
    $argStr = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$updater`" -ProcId $PID -Source `"$src`" -Target `"$($script:AppRoot)`""
    Start-Process -FilePath powershell.exe -ArgumentList $argStr -WindowStyle Hidden
    $script:form.Close()
}

function Invoke-UpdateCheck([bool]$Silent) {
    try {
        $script:form.Cursor = 'WaitCursor'
        $rel = Get-LatestRelease
        $remote = ConvertTo-VersionObject $rel.tag_name
        $local = [version]$script:AppVersion
        if ($remote -gt $local) {
            $answer = [System.Windows.Forms.MessageBox]::Show(
                "BrandyTheme $remote is available (you have $local).`r`n`r`nDownload and install it now?",
                'Update available', 'YesNo', 'Information')
            if ($answer -eq 'Yes') { Install-Update $rel }
        } elseif (-not $Silent) {
            [void][System.Windows.Forms.MessageBox]::Show("You are running the latest version ($local).", 'BrandyTheme', 'OK', 'Information')
        }
    } catch {
        if ($Silent) { Write-Log "Update check skipped: $($_.Exception.Message)" }
        else { [void][System.Windows.Forms.MessageBox]::Show("Could not check for updates:`r`n$($_.Exception.Message)", 'BrandyTheme', 'OK', 'Warning') }
    } finally { $script:form.Cursor = 'Default' }
}

# ------------------------------------------------------------------ GUI
function New-Ctl([string]$Type, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Text = '') {
    $c = New-Object "System.Windows.Forms.$Type"
    $c.Location = New-Object System.Drawing.Point($X, $Y)
    $c.Size = New-Object System.Drawing.Size($W, $H)
    if ($Text) { $c.Text = $Text }
    $c
}

function Get-SelectedBrand { if ($script:lbBrand.SelectedIndex -ge 0) { $script:Brands[$script:lbBrand.SelectedIndex] } }

function Update-Preview {
    $brand = Get-SelectedBrand
    if (-not $brand) { return }
    foreach ($pair in @(@($script:pbWall, 'Wallpaper'), @($script:pbLock, 'Lock'))) {
        $old = $pair[0].Image
        $pair[0].Image = New-BrandBitmap $brand 624 351 $pair[1]
        if ($old) { $old.Dispose() }
    }
    foreach ($pb in $script:flowIcons.Controls) {
        $old = $pb.Image
        $pb.Image = New-BrandIconBitmap $pb.Tag $brand 256
        if ($old) { $old.Dispose() }
    }
}

function Invoke-Step([string]$Label, [scriptblock]$Action) {
    try { & $Action; Write-Log "OK      $Label" }
    catch { Write-Log "FAILED  $Label - $($_.Exception.Message)" }
}

function Invoke-Apply {
    $brand = Get-SelectedBrand
    if (-not $brand) { return }
    if (-not ($script:cbWall.Checked -or $script:cbLock.Checked -or $script:cbAccent.Checked -or $script:cbDark.Checked -or
              $script:cbIcons.Checked -or $script:cbDesk.Checked -or $script:cbStart.Checked)) {
        [void][System.Windows.Forms.MessageBox]::Show('Tick at least one item to apply.', $script:AppName, 'OK', 'Information'); return
    }
    $script:form.Enabled = $false; $script:form.Cursor = 'WaitCursor'
    try {
        $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        Write-Log "Applying the $($brand.Name) theme..."
        $icons = $null
        if ($script:cbIcons.Checked -or $script:cbDesk.Checked -or $script:cbStart.Checked) {
            Invoke-Step 'Generate icon set' { $script:icons = Build-BrandIcons $brand }
            $icons = $script:icons
        }
        if ($script:cbWall.Checked)   { Invoke-Step 'Desktop wallpaper'  { Set-BrandWallpaper $brand $b.Width $b.Height } }
        if ($script:cbLock.Checked)   { Invoke-Step 'Lock screen'        { Set-BrandLockScreen $brand $b.Width $b.Height } }
        if ($script:cbAccent.Checked) { Invoke-Step 'Accent colour'      { Set-BrandAccent $brand $script:cbDark.Checked } }
        elseif ($script:cbDark.Checked) { Invoke-Step 'Dark mode'        { Set-DarkModeOnly } }
        if ($icons) {
            if ($script:cbIcons.Checked) { Invoke-Step 'File, folder, drive and app icons' { Set-ShellIcons $icons } }
            if ($script:cbDesk.Checked)  { Invoke-Step 'Desktop system icons'              { Set-DesktopIcons $icons } }
            if ($script:cbStart.Checked) { Invoke-Step 'Start menu folder icons'           { Set-StartFolderIcons $icons } }
        }
        Write-State
        Invoke-Step 'Refresh shell' { Update-ShellIcons }
        Write-Log 'Finished. Icons and accent colours may need a sign-out (or restart) to appear everywhere.'
    } finally { $script:form.Enabled = $true; $script:form.Cursor = 'Default' }
}

function Show-About {
    $f = New-Ctl 'Form' 0 0 420 300
    $f.Text = "About $($script:AppName)"
    $f.FormBorderStyle = 'FixedDialog'; $f.MaximizeBox = $false; $f.MinimizeBox = $false; $f.StartPosition = 'CenterParent'
    $f.ClientSize = New-Object System.Drawing.Size(420, 300)
    $pb = New-Ctl 'PictureBox' 20 20 64 64
    $pb.SizeMode = 'Zoom'; $pb.Image = New-AppIconBitmap 128
    $t = New-Ctl 'Label' 100 20 300 32 $script:AppName
    $t.Font = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold)
    $v = New-Ctl 'Label' 102 58 300 20 "Version $($script:AppVersion)"
    $a = New-Ctl 'Label' 20 100 380 20 "Created by $($script:Author)"
    $a.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $e = New-Ctl 'LinkLabel' 20 126 380 20 "Contact: $($script:Email)"
    $e.Tag = "mailto:$($script:Email)"
    $gh = New-Ctl 'LinkLabel' 20 150 380 20 "GitHub: $($script:GitHubUrl)"
    $gh.Tag = $script:GitHubUrl
    foreach ($l in $e, $gh) { $l.Add_LinkClicked({ param($s, $ev) Start-Process $s.Tag }) }
    $d = New-Ctl 'Label' 20 184 380 60 'Brand names and logos are trademarks of their respective owners. BrandyTheme is an independent tool and is not affiliated with or endorsed by HP, Lenovo, Samsung, Intel or AMD.'
    $ok = New-Ctl 'Button' 310 256 90 30 'OK'
    $ok.DialogResult = 'OK'; $f.AcceptButton = $ok
    $f.Controls.AddRange(@($pb, $t, $v, $a, $e, $gh, $d, $ok))
    [void]$f.ShowDialog($script:form)
    $pb.Image.Dispose(); $f.Dispose()
}

try {
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $script:form = New-Object System.Windows.Forms.Form
    $form = $script:form
    $form.Text = "$($script:AppName) $($script:AppVersion)"
    $form.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $form.AutoScaleMode = 'Dpi'
    $form.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $form.ClientSize = New-Object System.Drawing.Size(860, 660)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedSingle'; $form.MaximizeBox = $false
    $iconBmp = New-AppIconBitmap 64
    $form.Icon = [System.Drawing.Icon]::FromHandle($iconBmp.GetHicon())

    # ---- menu
    $menu = New-Object System.Windows.Forms.MenuStrip
    $mFile = New-Object System.Windows.Forms.ToolStripMenuItem('&File')
    $mData = New-Object System.Windows.Forms.ToolStripMenuItem('Open &data folder')
    $mLogo = New-Object System.Windows.Forms.ToolStripMenuItem('Open &custom logos folder')
    $mExit = New-Object System.Windows.Forms.ToolStripMenuItem('E&xit')
    $mData.Add_Click({ Start-Process explorer.exe $script:DataDir })
    $mLogo.Add_Click({ Start-Process explorer.exe $script:LogoDir })
    $mExit.Add_Click({ $script:form.Close() })
    [void]$mFile.DropDownItems.AddRange(@($mData, $mLogo, (New-Object System.Windows.Forms.ToolStripSeparator), $mExit))

    $mHelp = New-Object System.Windows.Forms.ToolStripMenuItem('&Help')
    $mUpd  = New-Object System.Windows.Forms.ToolStripMenuItem('Check for &updates...')
    $mAuto = New-Object System.Windows.Forms.ToolStripMenuItem('Check for updates &automatically')
    $mWeb  = New-Object System.Windows.Forms.ToolStripMenuItem('&GitHub repository')
    $mAbt  = New-Object System.Windows.Forms.ToolStripMenuItem('&About BrandyTheme')
    $mAuto.CheckOnClick = $true; $mAuto.Checked = [bool]$script:Settings.AutoUpdate
    $mUpd.Add_Click({ Invoke-UpdateCheck $false })
    $mAuto.Add_CheckedChanged({ $script:Settings.AutoUpdate = $mAuto.Checked; Write-Settings })
    $mWeb.Add_Click({ Start-Process $script:GitHubUrl })
    $mAbt.Add_Click({ Show-About })
    [void]$mHelp.DropDownItems.AddRange(@($mUpd, $mAuto, $mWeb, (New-Object System.Windows.Forms.ToolStripSeparator), $mAbt))
    [void]$menu.Items.AddRange(@($mFile, $mHelp))
    $form.MainMenuStrip = $menu

    # ---- brand list
    $grpBrand = New-Ctl 'GroupBox' 12 30 180 204 '1. Choose a brand'
    $script:lbBrand = New-Ctl 'ListBox' 10 22 160 172
    $lbBrand = $script:lbBrand
    $lbBrand.DrawMode = 'OwnerDrawFixed'; $lbBrand.ItemHeight = 30; $lbBrand.BorderStyle = 'None'
    foreach ($br in $script:Brands) { [void]$lbBrand.Items.Add($br.Name) }
    $lbBrand.Add_DrawItem({
        param($s, $e)
        $e.DrawBackground()
        if ($e.Index -ge 0) {
            $br = $script:Brands[$e.Index]
            $sw = New-Object System.Drawing.SolidBrush (ConvertTo-Color $br.Primary)
            $tx = New-Object System.Drawing.SolidBrush $e.ForeColor
            $e.Graphics.FillRectangle($sw, $e.Bounds.X + 6, $e.Bounds.Y + 6, 22, $e.Bounds.Height - 12)
            $e.Graphics.DrawString($br.Name, $e.Font, $tx, $e.Bounds.X + 38, $e.Bounds.Y + 7)
            $sw.Dispose(); $tx.Dispose()
        }
        $e.DrawFocusRectangle()
    })
    $lbBrand.Add_SelectedIndexChanged({ Update-Preview })
    $grpBrand.Controls.Add($lbBrand)

    # ---- previews
    $lblW = New-Ctl 'Label' 204 32 300 18 'Wallpaper preview'
    $lblL = New-Ctl 'Label' 528 32 300 18 'Lock screen preview'
    $script:pbWall = New-Ctl 'PictureBox' 204 52 312 176; $script:pbWall.SizeMode = 'Zoom'
    $script:pbLock = New-Ctl 'PictureBox' 528 52 312 176; $script:pbLock.SizeMode = 'Zoom'
    $pbWall = $script:pbWall; $pbLock = $script:pbLock

    $grpIcons = New-Ctl 'GroupBox' 204 236 644 76 'Icon set preview'
    $script:flowIcons = New-Ctl 'FlowLayoutPanel' 8 16 628 56
    foreach ($k in 'Folder', 'File', 'App', 'Drive', 'Pc', 'Recycle', 'Network', 'Control') {
        $pb = New-Ctl 'PictureBox' 0 0 50 50
        $pb.SizeMode = 'Zoom'; $pb.Tag = $k; $pb.Margin = New-Object System.Windows.Forms.Padding(4)
        $script:flowIcons.Controls.Add($pb)
    }
    $grpIcons.Controls.Add($script:flowIcons)

    # ---- options
    $grpOpt = New-Ctl 'GroupBox' 12 320 836 132 '2. What to apply'
    $script:cbWall   = New-Ctl 'CheckBox' 16 24 400 22 'Desktop wallpaper'
    $script:cbLock   = New-Ctl 'CheckBox' 16 50 400 22 'Lock screen and sign-in background'
    $script:cbAccent = New-Ctl 'CheckBox' 16 76 400 22 'Accent colour (Start, taskbar, title bars)'
    $script:cbDark   = New-Ctl 'CheckBox' 16 102 400 22 'Switch Windows to dark mode (needed to show accent on Start/taskbar)'
    $script:cbIcons  = New-Ctl 'CheckBox' 440 24 390 22 'System-wide file, folder, drive and app icons'
    $script:cbDesk   = New-Ctl 'CheckBox' 440 50 390 22 'Desktop icons: This PC, Recycle Bin, Network, Control Panel'
    $script:cbStart  = New-Ctl 'CheckBox' 440 76 390 22 'Start menu folder icons'
    foreach ($cb in $script:cbWall, $script:cbLock, $script:cbAccent, $script:cbIcons, $script:cbDesk, $script:cbStart) { $cb.Checked = $true }
    $script:cbDark.Checked = $false
    $grpOpt.Controls.AddRange(@($script:cbWall, $script:cbLock, $script:cbAccent, $script:cbDark, $script:cbIcons, $script:cbDesk, $script:cbStart))

    # ---- buttons + log
    $btnApply = New-Ctl 'Button' 12 462 170 38 'Apply theme'
    $btnApply.BackColor = [System.Drawing.Color]::FromArgb(0, 103, 192); $btnApply.ForeColor = 'White'; $btnApply.FlatStyle = 'Flat'
    $btnRestore = New-Ctl 'Button' 194 462 170 38 'Restore Windows defaults'
    $btnApply.Add_Click({ Invoke-Apply })
    $btnRestore.Add_Click({
        $a = [System.Windows.Forms.MessageBox]::Show('Revert everything BrandyTheme changed back to your original settings?', $script:AppName, 'YesNo', 'Question')
        if ($a -eq 'Yes') {
            $script:form.Enabled = $false
            try { Restore-All } finally { $script:form.Enabled = $true }
        }
    })
    $script:txtLog = New-Ctl 'TextBox' 12 510 836 140
    $script:txtLog.Multiline = $true; $script:txtLog.ReadOnly = $true; $script:txtLog.ScrollBars = 'Vertical'
    $script:txtLog.Font = New-Object System.Drawing.Font('Consolas', 9)

    $form.Controls.AddRange(@($menu, $grpBrand, $lblW, $lblL, $pbWall, $pbLock, $grpIcons, $grpOpt, $btnApply, $btnRestore, $script:txtLog))

    $form.Add_Shown({
        $script:lbBrand.SelectedIndex = 0
        Write-Log "$($script:AppName) $($script:AppVersion) ready. Changes are backed up so 'Restore Windows defaults' can undo them."
        Write-Log "Tip: drop licensed logos named like HP.png into $($script:LogoDir) to use them on wallpapers."
        if ($script:Settings.AutoUpdate -and -not $NoUpdateCheck) { Invoke-UpdateCheck $true }
    })

    [System.Windows.Forms.Application]::Run($form)
} catch {
    [void][System.Windows.Forms.MessageBox]::Show("BrandyTheme hit an unexpected error:`r`n`r`n$($_.Exception.Message)", $script:AppName, 'OK', 'Error')
    exit 1
}
