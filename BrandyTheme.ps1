#Requires -Version 5.1
<#
.SYNOPSIS
    BrandyTheme - branded wallpapers, lock screens, accent colours and icon sets for Windows 10/11.

.DESCRIPTION
    40 brands. Every brand has its own colours and art styles and offers 12 wallpapers plus
    12 lock screens (960 distinct images), generated locally - clean colour artwork, no text or logos.

.NOTES
    Author  : Tasmon Islam <tasmon@outlook.com>
    Updates : version.txt + BrandyTheme.ps1 in github.com/tasmon/BrandyTheme (main branch)

.PARAMETER NoUpdateCheck    Skip the automatic update check at start-up.
.PARAMETER ExportAppIcon    (Installer) Write BrandyTheme.ico to ProgramData and exit.
.PARAMETER RestoreDefaults  (Uninstaller) Revert every change BrandyTheme made, without the GUI.
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
$script:AppVersion  = '1.2.0'
$script:Author      = 'Tasmon Islam'
$script:Email       = 'tasmon@outlook.com'
$script:GitHubOwner = 'tasmon'
$script:GitHubRepo  = 'BrandyTheme'          # <- change if your repository has another name
$script:GitHubBranch = 'main'
$script:GitHubUrl   = "https://github.com/$($script:GitHubOwner)/$($script:GitHubRepo)"
$script:VariantCount = 12                    # wallpapers (and lock screens) per brand

$script:AppRoot = $PSScriptRoot
if (-not $script:AppRoot) { $script:AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path }
$script:DataDir      = Join-Path $env:ProgramData 'BrandyTheme'
$script:StatePath    = Join-Path $script:DataDir 'state.json'
$script:SettingsPath = Join-Path $script:DataDir 'settings.json'
$script:IconPath     = Join-Path $script:DataDir 'BrandyTheme.ico'
$script:txtLog       = $null
$script:lblStatus    = $null
$script:LogLines     = New-Object 'System.Collections.Generic.List[string]'

foreach ($d in @($script:DataDir)) {
    if (-not (Test-Path -LiteralPath $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ------------------------------------------------------------------ brands (40)
# Name | primary | dark | secondary | category | art styles (4)
$script:BrandTable = @'
HP|#0096D6|#00263E|#7FD3F5|PC maker|Waves,Rings,Glow,Bokeh
Lenovo|#E2231A|#1B1B1B|#FF7A72|PC maker|Stripes,Dots,Chevrons,Grid
Samsung|#1428A0|#050B33|#5C7CFF|Electronics|Waves,Glow,Bokeh,Rings
Intel|#0071C5|#00162E|#00C7FD|Chips|Circuit,Grid,Rings,Hex
AMD|#ED1C24|#0D0D0D|#FF7A7F|Chips|Chevrons,Stripes,Triangles,Burst
Ryzen|#F26B21|#1A0D05|#FFB26B|Chips|Hex,Burst,Chevrons,Circuit
Dell|#007DB8|#00202F|#7FD0F2|PC maker|Rings,Circuit,Glow,Dots
ASUS|#1F6FD1|#00152B|#6FB0FF|PC maker|Triangles,Waves,Glow,Grid
Acer|#83B81A|#0F1A04|#C5E86C|PC maker|Hex,Bokeh,Waves,Dots
MSI|#E60012|#0B0B0B|#FF5A66|Gaming|Triangles,Chevrons,Burst,Stripes
Microsoft|#0078D4|#001A33|#50E6FF|Software|Glow,Waves,Dots,Bokeh
Apple|#8E8E93|#0A0A0C|#D2D2D7|Electronics|Glow,Bokeh,Waves,Rings
NVIDIA|#76B900|#0A1200|#B6FF3C|Graphics|Grid,Hex,Circuit,Triangles
GeForce|#8BD100|#0B0F05|#D4FF6B|Graphics|Burst,Triangles,Chevrons,Stripes
Radeon|#ED1C24|#120305|#FF6A6F|Graphics|Burst,Grid,Chevrons,Circuit
Razer|#44D62C|#050505|#00FF9C|Gaming|Triangles,Hex,Grid,Burst
Alienware|#00C2B8|#02161A|#7FFFF0|Gaming|Circuit,Glow,Hex,Rings
Gigabyte|#F7941D|#1A1002|#FFD27F|Hardware|Triangles,Stripes,Circuit,Dots
Logitech|#00B8FC|#001B2A|#7BE0FF|Peripherals|Rings,Dots,Waves,Bokeh
Corsair|#FFD100|#141000|#FFE97A|Gaming|Chevrons,Stripes,Burst,Hex
Sony|#6B7280|#050506|#E5E7EB|Electronics|Glow,Grid,Rings,Bokeh
LG|#A50034|#1A0010|#FF6F9F|Electronics|Waves,Dots,Glow,Rings
Toshiba|#E60000|#140000|#FF7B7B|Electronics|Stripes,Circuit,Rings,Grid
Huawei|#CF0A2C|#180008|#FF6B87|Mobile|Burst,Waves,Dots,Hex
Xiaomi|#FF6900|#1A0A00|#FFB066|Mobile|Dots,Triangles,Glow,Stripes
Google|#4285F4|#0B1B3B|#FBBC05|Software|Bokeh,Dots,Waves,Glow
Qualcomm|#3253DC|#0A1033|#7B93FF|Chips|Circuit,Hex,Rings,Grid
Snapdragon|#C8102E|#14040A|#FF5C7A|Chips|Hex,Burst,Chevrons,Triangles
Canon|#CC0000|#150000|#FF6666|Imaging|Rings,Bokeh,Stripes,Burst
Epson|#2A5CC7|#000D26|#7FA6F0|Imaging|Waves,Grid,Dots,Circuit
Western Digital|#0A7CCF|#001A2E|#5CB8FF|Storage|Rings,Triangles,Grid,Hex
Seagate|#6EBE44|#0C1A06|#B5E88F|Storage|Hex,Waves,Circuit,Bokeh
Kingston|#D71920|#120304|#FF8A8E|Storage|Chevrons,Dots,Circuit,Stripes
ThinkPad|#D9231A|#050505|#FFFFFF|PC maker|Grid,Chevrons,Stripes,Circuit
ROG|#FF0033|#07070A|#FF5577|Gaming|Chevrons,Triangles,Burst,Grid
Legion|#0D6EFD|#02081A|#6FA8FF|Gaming|Grid,Chevrons,Hex,Triangles
Predator|#1AA7EC|#021018|#59D4FF|Gaming|Triangles,Burst,Circuit,Stripes
Xbox|#107C10|#021002|#6BD66B|Gaming|Burst,Glow,Hex,Rings
Surface|#4F6BED|#0B0F33|#A5B4FF|PC maker|Waves,Glow,Rings,Bokeh
PlayStation|#0070D1|#000A20|#4D8DFF|Gaming|Dots,Grid,Glow,Triangles
'@

$script:Brands = @()
foreach ($line in ($script:BrandTable -split "`r?`n")) {
    if (-not $line.Trim()) { continue }
    $f = $line.Split('|')
    $script:Brands += [pscustomobject]@{
        Name = $f[0]; Primary = $f[1]; Dark = $f[2]; Secondary = $f[3]; Category = $f[4]
        Styles = [string[]]$f[5].Split(',')
    }
}

# ------------------------------------------------------------------ drawing helpers
function ConvertTo-Color([string]$Hex) { [System.Drawing.ColorTranslator]::FromHtml($Hex) }

function Get-Mix([System.Drawing.Color]$A, [System.Drawing.Color]$B, [double]$T) {
    [System.Drawing.Color]::FromArgb(255,
        [int]($A.R + ($B.R - $A.R) * $T),
        [int]($A.G + ($B.G - $A.G) * $T),
        [int]($A.B + ($B.B - $A.B) * $T))
}

function New-Alpha([System.Drawing.Color]$C, [int]$A) {
    [System.Drawing.Color]::FromArgb([Math]::Max(0, [Math]::Min(255, $A)), $C.R, $C.G, $C.B)
}

function Get-ContrastText([System.Drawing.Color]$C) {
    if ((0.299 * $C.R + 0.587 * $C.G + 0.114 * $C.B) -gt 165) { [System.Drawing.Color]::Black } else { [System.Drawing.Color]::White }
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

function Add-Ln($g, $Pen, $X1, $Y1, $X2, $Y2) { $g.DrawLine($Pen, [single]$X1, [single]$Y1, [single]$X2, [single]$Y2) }
function Add-FillOval($g, $Br, $X, $Y, $W, $H) { $g.FillEllipse($Br, [single]$X, [single]$Y, [single]$W, [single]$H) }
function Add-DrawOval($g, $Pen, $X, $Y, $W, $H) { $g.DrawEllipse($Pen, [single]$X, [single]$Y, [single]$W, [single]$H) }

function Add-Glow($g, [double]$Cx, [double]$Cy, [double]$R, $Color, [int]$Alpha) {
    $gp = New-Object System.Drawing.Drawing2D.GraphicsPath
    $gp.AddEllipse([single]($Cx - $R), [single]($Cy - $R), [single](2 * $R), [single](2 * $R))
    $pb = New-Object System.Drawing.Drawing2D.PathGradientBrush($gp)
    $pb.CenterColor = New-Alpha $Color $Alpha
    $pb.SurroundColors = [System.Drawing.Color[]]@((New-Alpha $Color 0))
    $g.FillPath($pb, $gp)
    $pb.Dispose(); $gp.Dispose()
}

function Get-BrandSeed([string]$Name, [int]$Variant, [int]$Salt) {
    $h = 17
    foreach ($chr in $Name.ToCharArray()) { $h = ($h * 31 + [int]$chr) % 2147000000 }
    [int](($h + $Variant * 7919 + $Salt * 104729) % 2147000000)
}

# Every brand has 4 art styles x 3 palettes = 12 looks; wallpaper and lock screen use different combinations + seeds
function Get-VariantInfo($Brand, [int]$Variant, [string]$Mode) {
    $n = $Brand.Styles.Count
    $lock = ($Mode -eq 'Lock')
    $styleIdx = ($Variant + $(if ($lock) { 2 } else { 0 })) % $n
    $palIdx   = ([int][Math]::Floor($Variant / $n) + $(if ($lock) { 1 } else { 0 })) % 3
    [pscustomobject]@{ Style = $Brand.Styles[$styleIdx]; Palette = $palIdx; PaletteName = @('Classic', 'Inverted', 'Midnight')[$palIdx] }
}

# ------------------------------------------------------------------ 12 art styles
function Invoke-BrandArt {
    param($g, [int]$CW, [int]$CH, [string]$Style, $rng, $Pri, $Sec, $Drk)
    $u = [double]$CH
    $white = [System.Drawing.Color]::White
    $PF = [System.Drawing.PointF]

    switch ($Style) {
        'Glow' {
            for ($i = 0; $i -lt 7; $i++) {
                $col = if ($i % 2) { $Sec } else { $Pri }
                Add-Glow $g ($CW * $rng.NextDouble()) ($CH * $rng.NextDouble()) ($u * (0.45 + 0.55 * $rng.NextDouble())) $col (80 + $rng.Next(80))
            }
        }
        'Waves' {
            for ($i = 0; $i -lt 6; $i++) {
                $base = $u * (0.36 + 0.1 * $i); $amp = $u * (0.025 + 0.045 * $rng.NextDouble())
                $fr = 1 + 2 * $rng.NextDouble(); $ph = 6.28 * $rng.NextDouble()
                $pts = New-Object 'System.Collections.Generic.List[System.Drawing.PointF]'
                $step = $CW / 60.0
                for ($x = 0.0; $x -le $CW + $step; $x += $step) {
                    $pts.Add($PF::new([single]$x, [single]($base + $amp * [Math]::Sin(6.2832 * $fr * $x / $CW + $ph))))
                }
                $pts.Add($PF::new([single]($CW + 10), [single]($CH + 10))); $pts.Add($PF::new(-10, [single]($CH + 10)))
                $col = if ($i % 2) { $Sec } else { $Pri }
                $br = New-SolidBrush (New-Alpha $col (24 + $i * 9))
                $g.FillPolygon($br, $pts.ToArray()); $br.Dispose()
            }
        }
        'Rings' {
            $cx = $CW * (0.2 + 0.6 * $rng.NextDouble()); $cy = $CH * (0.2 + 0.6 * $rng.NextDouble()); $n = 14 + $rng.Next(8)
            Add-Glow $g $cx $cy ($u * 0.55) $Sec 85
            for ($i = 1; $i -le $n; $i++) {
                $r = $u * 0.09 * $i; $a = [int](130 - $i * (115.0 / $n))
                $col = if ($i % 3 -eq 0) { $Sec } else { $white }
                $pen = New-Object System.Drawing.Pen((New-Alpha $col ([Math]::Max(10, [int]($a * 0.7)))), [single]([Math]::Max(1, $u * 0.003)))
                Add-DrawOval $g $pen ($cx - $r) ($cy - $r) (2 * $r) (2 * $r); $pen.Dispose()
            }
        }
        'Hex' {
            $sz = $u / 8.5; $hw = [Math]::Sqrt(3) * $sz
            $pen = New-Object System.Drawing.Pen((New-Alpha $white 28), [single]([Math]::Max(1, $u * 0.0025)))
            $b1 = New-SolidBrush (New-Alpha $Pri 80); $b2 = New-SolidBrush (New-Alpha $Sec 62); $b3 = New-SolidBrush (New-Alpha $white 22)
            $rows = [int]($CH / ($sz * 1.5)) + 2; $cols = [int]($CW / $hw) + 2
            $hp = New-Object 'System.Drawing.PointF[]' 6
            for ($rr = -1; $rr -lt $rows; $rr++) {
                for ($cc = -1; $cc -lt $cols; $cc++) {
                    $cx = $cc * $hw + (($rr -band 1) * $hw / 2); $cy = $rr * $sz * 1.5
                    for ($k = 0; $k -lt 6; $k++) {
                        $ang = [Math]::PI / 180 * (60 * $k - 30)
                        $hp[$k] = $PF::new([single]($cx + $sz * 0.96 * [Math]::Cos($ang)), [single]($cy + $sz * 0.96 * [Math]::Sin($ang)))
                    }
                    $roll = $rng.Next(100)
                    if ($roll -lt 14) { $g.FillPolygon($b1, $hp) } elseif ($roll -lt 24) { $g.FillPolygon($b2, $hp) } elseif ($roll -lt 31) { $g.FillPolygon($b3, $hp) }
                    $g.DrawPolygon($pen, $hp)
                }
            }
            $pen.Dispose(); $b1.Dispose(); $b2.Dispose(); $b3.Dispose()
        }
        'Circuit' {
            $gr = $u / 24
            $pen = New-Object System.Drawing.Pen((New-Alpha $Sec 100), [single]([Math]::Max(1.5, $u * 0.0035)))
            $nb = New-SolidBrush (New-Alpha $Sec 170)
            for ($t = 0; $t -lt 36; $t++) {
                $x = [Math]::Round($CW * $rng.NextDouble() / $gr) * $gr; $y = [Math]::Round($CH * $rng.NextDouble() / $gr) * $gr
                $segs = 3 + $rng.Next(5)
                Add-FillOval $g $nb ($x - $gr * 0.25) ($y - $gr * 0.25) ($gr * 0.5) ($gr * 0.5)
                for ($sg = 0; $sg -lt $segs; $sg++) {
                    $dx = $rng.Next(-1, 2); $dy = $rng.Next(-1, 2); if ($dx -eq 0 -and $dy -eq 0) { $dx = 1 }
                    $len = $gr * (1 + $rng.Next(5)); $nx = $x + $dx * $len; $ny = $y + $dy * $len
                    Add-Ln $g $pen $x $y $nx $ny; $x = $nx; $y = $ny
                }
                Add-FillOval $g $nb ($x - $gr * 0.35) ($y - $gr * 0.35) ($gr * 0.7) ($gr * 0.7)
            }
            $pen.Dispose(); $nb.Dispose()
        }
        'Triangles' {
            $g.SmoothingMode = 'None'
            $tile = $u / 9; $cols = [int]($CW / $tile) + 2; $rows = [int]($CH / $tile) + 2
            $pal = @()
            foreach ($t in 0.0, 0.25, 0.5, 0.75, 1.0) { $pal += New-SolidBrush (New-Alpha (Get-Mix $Drk $Pri $t) (30 + $rng.Next(50))) }
            $pal += New-SolidBrush (New-Alpha $Sec 46); $pal += New-SolidBrush (New-Alpha $white 20)
            for ($rr = 0; $rr -lt $rows; $rr++) {
                for ($cc = 0; $cc -lt $cols; $cc++) {
                    $x0 = $cc * $tile; $y0 = $rr * $tile; $x1 = $x0 + $tile; $y1 = $y0 + $tile
                    if ($rng.Next(2)) {
                        $g.FillPolygon($pal[$rng.Next($pal.Count)], (New-Pts $x0, $y0, $x1, $y0, $x0, $y1))
                        $g.FillPolygon($pal[$rng.Next($pal.Count)], (New-Pts $x1, $y0, $x1, $y1, $x0, $y1))
                    } else {
                        $g.FillPolygon($pal[$rng.Next($pal.Count)], (New-Pts $x0, $y0, $x1, $y1, $x0, $y1))
                        $g.FillPolygon($pal[$rng.Next($pal.Count)], (New-Pts $x0, $y0, $x1, $y0, $x1, $y1))
                    }
                }
            }
            foreach ($b in $pal) { $b.Dispose() }
            $g.SmoothingMode = 'AntiAlias'
        }
        'Stripes' {
            $sl = $u * 0.7; $x = -$sl
            while ($x -lt $CW) {
                $wd = $u * (0.03 + 0.25 * $rng.NextDouble())
                $col = if ($rng.Next(2)) { $Sec } else { $Pri }
                $br = New-SolidBrush (New-Alpha $col (22 + $rng.Next(70)))
                $g.FillPolygon($br, (New-Pts $x, $CH, ($x + $wd), $CH, ($x + $wd + $sl), 0, ($x + $sl), 0)); $br.Dispose()
                $x += $wd + $u * (0.02 + 0.12 * $rng.NextDouble())
            }
            $pen = New-Object System.Drawing.Pen((New-Alpha $white 60), [single]([Math]::Max(1.5, $u * 0.004)))
            for ($i = 0; $i -lt 4; $i++) { $x = $CW * $rng.NextDouble(); Add-Ln $g $pen $x $CH ($x + $sl) 0 }
            $pen.Dispose()
        }
        'Grid' {
            $hz = $CH * (0.50 + 0.12 * $rng.NextDouble()); $sr = $u * (0.14 + 0.08 * $rng.NextDouble()); $scx = $CW * (0.25 + 0.5 * $rng.NextDouble())
            Add-Glow $g $scx $hz ($u * 0.9) $Sec 90
            $g.SetClip([System.Drawing.RectangleF]::new(0, 0, [single]$CW, [single]$hz))
            $sb = New-Object System.Drawing.Drawing2D.LinearGradientBrush($PF::new([single]$scx, [single]($hz - 2.2 * $sr)), $PF::new([single]$scx, [single]$hz), $Sec, $Pri)
            Add-FillOval $g $sb ($scx - $sr) ($hz - 1.7 * $sr) (2 * $sr) (2 * $sr)
            $g.ResetClip(); $sb.Dispose()
            $fl = New-SolidBrush (New-Alpha $Drk 190)
            $g.FillRectangle($fl, [single]0, [single]$hz, [single]$CW, [single]($CH - $hz)); $fl.Dispose()
            $pen = New-Object System.Drawing.Pen((New-Alpha $Sec 125), [single]([Math]::Max(1, $u * 0.003)))
            for ($i = -16; $i -le 16; $i++) { Add-Ln $g $pen ($CW / 2 + $i * $CW * 0.012) $hz ($CW / 2 + $i * $CW * 0.12) $CH }
            for ($k = 1; $k -le 12; $k++) { $t = $k / 12.0; $y = $hz + ($CH - $hz) * $t * $t; Add-Ln $g $pen 0 $y $CW $y }
            Add-Ln $g $pen 0 $hz $CW $hz
            $pen.Dispose()
        }
        'Bokeh' {
            for ($i = 0; $i -lt 48; $i++) {
                $r = $u * (0.015 + 0.10 * $rng.NextDouble()); $x = $CW * $rng.NextDouble(); $y = $CH * $rng.NextDouble()
                $col = @($white, $Pri, $Sec)[$rng.Next(3)]
                $br = New-SolidBrush (New-Alpha $col (14 + $rng.Next(46)))
                $pen = New-Object System.Drawing.Pen((New-Alpha $col 55), [single]([Math]::Max(1, $u * 0.002)))
                Add-FillOval $g $br ($x - $r) ($y - $r) (2 * $r) (2 * $r); Add-DrawOval $g $pen ($x - $r) ($y - $r) (2 * $r) (2 * $r)
                $br.Dispose(); $pen.Dispose()
            }
        }
        'Burst' {
            $cx = $CW * (0.15 + 0.7 * $rng.NextDouble()); $cy = $CH * (0.15 + 0.7 * $rng.NextDouble())
            $n = 24 + $rng.Next(30); $a = 6.28 * $rng.NextDouble(); $len = $CW * 2.0
            for ($i = 0; $i -lt $n; $i++) {
                $wv = 0.03 + 0.09 * $rng.NextDouble()
                $col = @($white, $Sec, $Pri)[$rng.Next(3)]
                $br = New-SolidBrush (New-Alpha $col (10 + $rng.Next(34)))
                $g.FillPolygon($br, (New-Pts $cx, $cy, ($cx + $len * [Math]::Cos($a)), ($cy + $len * [Math]::Sin($a)), ($cx + $len * [Math]::Cos($a + $wv)), ($cy + $len * [Math]::Sin($a + $wv))))
                $br.Dispose(); $a += 6.28 / $n
            }
            Add-Glow $g $cx $cy ($u * 0.5) $white 70
        }
        'Dots' {
            $sp = $u / 30; $fx = $CW * $rng.NextDouble(); $fy = $CH * $rng.NextDouble(); $maxd = [Math]::Sqrt($CW * $CW + $CH * $CH)
            $bw = New-SolidBrush (New-Alpha $white 70); $bs = New-SolidBrush (New-Alpha $Sec 110)
            $nx = [int]($CW / $sp) + 1; $ny = [int]($CH / $sp) + 1
            for ($i = 0; $i -lt $nx; $i++) {
                for ($j = 0; $j -lt $ny; $j++) {
                    $x = $i * $sp; $y = $j * $sp
                    $dist = [Math]::Sqrt(($x - $fx) * ($x - $fx) + ($y - $fy) * ($y - $fy))
                    $r = $sp * 0.52 * (1 - $dist / $maxd)
                    if ($r -gt 0.8) {
                        $br = if ((($i + $j) % 7) -eq 0) { $bs } else { $bw }
                        Add-FillOval $g $br ($x - $r) ($y - $r) (2 * $r) (2 * $r)
                    }
                }
            }
            $bw.Dispose(); $bs.Dispose()
        }
        'Chevrons' {
            $n = 7 + $rng.Next(4); $step = $CW / ($n + 1.0); $th = $u * (0.08 + 0.1 * $rng.NextDouble()); $dep = $u * (0.3 + 0.3 * $rng.NextDouble())
            for ($i = 0; $i -lt $n; $i++) {
                $x = $i * $step - $step * 0.3
                $col = if ($i % 2) { $Sec } else { $Pri }
                $br = New-SolidBrush (New-Alpha $col (26 + $i * 7))
                $g.FillPolygon($br, (New-Pts $x, 0, ($x + $dep), ($CH / 2), $x, $CH, ($x + $th), $CH, ($x + $dep + $th), ($CH / 2), ($x + $th), 0)); $br.Dispose()
            }
        }
    }
}

# Wallpaper / lock-screen artwork: brand palette x art style x seed (all different per brand/variant/mode)
function New-BrandBitmap {
    param($Brand, [int]$Width, [int]$Height, [string]$Mode = 'Wallpaper', [int]$Variant = 0)
    $bmp = New-Object System.Drawing.Bitmap($Width, $Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'; $g.InterpolationMode = 'HighQualityBicubic'
        $pri = ConvertTo-Color $Brand.Primary; $sec = ConvertTo-Color $Brand.Secondary; $drk = ConvertTo-Color $Brand.Dark
        $vi  = Get-VariantInfo $Brand $Variant $Mode
        $rng = New-Object System.Random (Get-BrandSeed $Brand.Name $Variant $(if ($Mode -eq 'Lock') { 1 } else { 0 }))

        # background by palette
        $rect = New-Object System.Drawing.Rectangle(0, 0, $Width, $Height)
        $angle = [single](20 + $rng.Next(60))
        switch ($vi.Palette) {
            0 { $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $drk, $pri, $angle) }
            1 { $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $pri, $drk, $angle) }
            2 { $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $drk, (Get-Mix $drk $pri 0.2), $angle) }
        }
        $g.FillRectangle($grad, $rect); $grad.Dispose()
        if ($vi.Palette -eq 2) {
            Add-Glow $g ($Width * 0.25) ($Height * 0.3) ($Height * 0.9) $pri 120
            Add-Glow $g ($Width * 0.8) ($Height * 0.8) ($Height * 0.8) $sec 70
        } else {
            Add-Glow $g ($Width * 0.12) ($Height * 0.05) ($Height * 0.8) ([System.Drawing.Color]::White) 40
        }

        Invoke-BrandArt $g $Width $Height $vi.Style $rng $pri $sec $drk

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
    Save-Ico $bmp $script:IconPath
    $bmp.Dispose()
    exit 0
}

# ------------------------------------------------------------------ elevation + STA
# (When started through BrandyTheme.exe the process is already elevated + STA, so nothing is relaunched.)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$isSta   = [System.Threading.Thread]::CurrentThread.GetApartmentState() -eq 'STA'
if (-not $isAdmin -or -not $isSta) {
    $argStr = "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
    if ($NoUpdateCheck)   { $argStr += ' -NoUpdateCheck' }
    if ($RestoreDefaults) { $argStr += ' -RestoreDefaults' }
    Start-Process -FilePath powershell.exe -ArgumentList $argStr -Verb RunAs -WindowStyle Hidden
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
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, string lParam);
    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value, int size);
    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    public static extern int SetCurrentProcessExplicitAppUserModelID(string appId);
}
'@
}
[void][BrandyNative]::SetProcessDPIAware()

# Taskbar fix #1: if we are running inside powershell.exe (fallback launch), give the process its own
# AppUserModelID so Windows shows BrandyTheme's icon instead of grouping it under PowerShell.
# (Launched through BrandyTheme.exe this is not needed - the exe owns its identity and icon.)
try {
    if ((Get-Process -Id $PID).ProcessName -match '^(powershell|pwsh|powershell_ise)$') {
        [void][BrandyNative]::SetCurrentProcessExplicitAppUserModelID('Tasmon.BrandyTheme')
    }
} catch { }

# ------------------------------------------------------------------ logging, settings, state
function Write-Log([string]$Message) {
    $line = "[{0:HH:mm:ss}] {1}" -f (Get-Date), $Message
    $script:LogLines.Add($line)
    if ($script:lblStatus) { $script:lblStatus.Text = $Message; [System.Windows.Forms.Application]::DoEvents() }
    elseif (-not $script:txtLog) { Write-Host $line }
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
    foreach ($guid in $script:ClsidMap.Keys) {
        foreach ($kp in @("HKCU:\Software\Classes\CLSID\$guid\DefaultIcon", "HKCU:\Software\Classes\CLSID\$guid")) {
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

function Set-BrandWallpaper($Brand, [int]$W, [int]$H, [int]$Variant) {
    $dir = Join-Path $script:DataDir 'Generated'
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $file = Join-Path $dir ("{0}-wallpaper-v{1}-{2:yyyyMMddHHmmss}.png" -f $Brand.Name, ($Variant + 1), (Get-Date))
    $bmp = New-BrandBitmap $Brand $W $H 'Wallpaper' $Variant
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    $desk = 'HKCU:\Control Panel\Desktop'
    Set-Reg $desk 'Wallpaper' $file 'String'
    Set-Reg $desk 'WallpaperStyle' '10' 'String'     # Fill
    Set-Reg $desk 'TileWallpaper' '0' 'String'
    [void][BrandyNative]::SystemParametersInfo(20, 0, $file, 3)
    Get-ChildItem -LiteralPath $dir -Filter '*-wallpaper-*.png' | Sort-Object LastWriteTime -Descending | Select-Object -Skip 3 |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

function Set-BrandLockScreen($Brand, [int]$W, [int]$H, [int]$Variant) {
    $dir = Join-Path $script:DataDir 'Lock'
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $file = Join-Path $dir ("{0}-lock-v{1}-{2:yyyyMMddHHmmss}.png" -f $Brand.Name, ($Variant + 1), (Get-Date))
    $bmp = New-BrandBitmap $Brand $W $H 'Lock' $Variant
    $bmp.Save($file, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
    $csp = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP'
    Set-Reg $csp 'LockScreenImagePath'   $file 'String'
    Set-Reg $csp 'LockScreenImageUrl'    $file 'String'
    Set-Reg $csp 'LockScreenImageStatus' 1     'DWord'
    Get-ChildItem -LiteralPath $dir -Filter '*-lock-*.png' | Sort-Object LastWriteTime -Descending | Select-Object -Skip 3 |
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
        Set-Reg $key '(default)' ("{0},0" -f $Icons[$kind]) 'String'
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
    Write-Log 'Restoring...'
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
    Write-Log 'Restored. Sign out and back in to finish.'
}

# headless restore (used by the uninstaller)
if ($RestoreDefaults) { Restore-All; exit 0 }

# ------------------------------------------------------------------ auto-update (simple version.txt)
# In the GitHub repo (main branch):
#   version.txt      first line = latest version, e.g.  1.2.0   (optional 2nd line = SHA-256 of BrandyTheme.ps1)
#   BrandyTheme.ps1  the latest script
function ConvertTo-VersionObject([string]$Text) {
    [version](($Text.Trim().TrimStart('v', 'V') -split '[-+\s]')[0])
}

function Get-RemoteVersion {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $base = "https://raw.githubusercontent.com/$($script:GitHubOwner)/$($script:GitHubRepo)/$($script:GitHubBranch)"
    $raw = (Invoke-WebRequest -Uri "$base/version.txt" -UseBasicParsing -TimeoutSec 8 `
            -Headers @{ 'User-Agent' = "$($script:AppName)/$($script:AppVersion)"; 'Cache-Control' = 'no-cache' }).Content
    if ($raw -is [byte[]]) { $raw = [System.Text.Encoding]::UTF8.GetString($raw) }
    $lines = @(($raw.TrimStart([char]0xFEFF) -split "`r?`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($lines.Count -eq 0) { throw 'version.txt is empty.' }
    [pscustomobject]@{
        Version = ConvertTo-VersionObject $lines[0]
        Sha256  = $(if ($lines.Count -gt 1) { $lines[1] } else { $null })
        Base    = $base
    }
}

function Install-Update($Remote) {
    $ProgressPreference = 'SilentlyContinue'
    $work = Join-Path $env:TEMP ('BrandyThemeUpdate-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $work -Force | Out-Null
    $file = Join-Path $work 'BrandyTheme.ps1'
    Write-Log 'Downloading update...'
    Invoke-WebRequest -Uri "$($Remote.Base)/BrandyTheme.ps1" -OutFile $file -UseBasicParsing -TimeoutSec 60

    if ($Remote.Sha256 -and ((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $Remote.Sha256)) {
        throw 'The download does not match the checksum in version.txt. Update cancelled.'
    }
    $tokens = $null; $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$tokens, [ref]$errors)
    if ($errors -and $errors.Count -gt 0) { throw 'The downloaded file is not a valid script. Update cancelled.' }
    $m = Select-String -Path $file -Pattern "AppVersion\s*=\s*'([^']+)'" | Select-Object -First 1
    if (-not $m -or ([version]$m.Matches[0].Groups[1].Value) -ne $Remote.Version) { throw 'The downloaded version does not match version.txt. Update cancelled.' }

    $updater = Join-Path $work 'apply-update.ps1'
    @'
param([int]$ProcId, [string]$Source, [string]$Target)
try { Wait-Process -Id $ProcId -Timeout 60 -ErrorAction SilentlyContinue } catch { }
Start-Sleep -Milliseconds 500
Copy-Item -LiteralPath $Source -Destination (Join-Path $Target 'BrandyTheme.ps1') -Force
$m = Select-String -Path (Join-Path $Target 'BrandyTheme.ps1') -Pattern "AppVersion\s*=\s*'([^']+)'" | Select-Object -First 1
if ($m) {
    $k = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\BrandyTheme'
    if (Test-Path $k) { Set-ItemProperty -Path $k -Name DisplayVersion -Value $m.Matches[0].Groups[1].Value }
}
$exe = Join-Path $Target 'BrandyTheme.exe'
if (Test-Path -LiteralPath $exe) { Start-Process -FilePath $exe }
else { Start-Process powershell.exe -ArgumentList ('-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "{0}"' -f (Join-Path $Target 'BrandyTheme.ps1')) }
'@ | Set-Content -LiteralPath $updater -Encoding UTF8

    Write-Log 'Restarting to finish the update...'
    $argStr = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$updater`" -ProcId $PID -Source `"$file`" -Target `"$($script:AppRoot)`""
    Start-Process -FilePath powershell.exe -ArgumentList $argStr -WindowStyle Hidden
    $script:form.Close()
}

function Invoke-UpdateCheck([bool]$Silent) {
    try {
        $script:form.Cursor = 'WaitCursor'
        $remote = Get-RemoteVersion
        $local = [version]$script:AppVersion
        if ($remote.Version -gt $local) {
            $answer = [System.Windows.Forms.MessageBox]::Show(
                "Version $($remote.Version) is available (you have $local).`r`n`r`nUpdate now?",
                'BrandyTheme update', 'YesNo', 'Information')
            if ($answer -eq 'Yes') { Install-Update $remote }
        } elseif (-not $Silent) {
            [void][System.Windows.Forms.MessageBox]::Show("You are up to date (version $local).", 'BrandyTheme', 'OK', 'Information')
        }
    } catch {
        if ($Silent) { Write-Log "Update check skipped: $($_.Exception.Message)" }
        else { [void][System.Windows.Forms.MessageBox]::Show("Could not check for updates:`r`n$($_.Exception.Message)", 'BrandyTheme', 'OK', 'Warning') }
    } finally { $script:form.Cursor = 'Default' }
}

# ------------------------------------------------------------------ modern UI helpers
$script:UI = @{
    Bg     = ConvertTo-Color '#0E1014'
    Side   = ConvertTo-Color '#13161C'
    Card   = ConvertTo-Color '#1A1D25'
    Card2  = ConvertTo-Color '#242833'
    Line   = ConvertTo-Color '#2A2F3B'
    Text   = ConvertTo-Color '#EEF0F4'
    Sub    = ConvertTo-Color '#8D95A5'
}
$script:FontReg  = New-Object System.Drawing.Font('Segoe UI', 9.5)
$script:FontSub  = New-Object System.Drawing.Font('Segoe UI', 8.5)
$script:FontSemi = New-Object System.Drawing.Font('Segoe UI Semibold', 10)
$script:FontBig  = New-Object System.Drawing.Font('Segoe UI Semibold', 22)
$script:FontApp  = New-Object System.Drawing.Font('Segoe UI Semibold', 13)

function New-Ctl([string]$Type, [int]$X, [int]$Y, [int]$W, [int]$H, [string]$Text = '') {
    $c = New-Object "System.Windows.Forms.$Type"
    $c.Location = New-Object System.Drawing.Point($X, $Y)
    $c.Size = New-Object System.Drawing.Size($W, $H)
    if ($Text) { $c.Text = $Text }
    $c
}

function Set-DoubleBuffer($Ctl) {
    try { $Ctl.GetType().GetProperty('DoubleBuffered', [System.Reflection.BindingFlags]'NonPublic,Instance').SetValue($Ctl, $true, $null) } catch { }
}

function Set-Rounded($Ctl, [int]$Radius) {
    if ($Ctl.Width -le 0 -or $Ctl.Height -le 0) { return }
    $gp = New-RoundRect 0 0 $Ctl.Width $Ctl.Height $Radius
    $old = $Ctl.Region
    $Ctl.Region = New-Object System.Drawing.Region($gp)
    if ($old) { $old.Dispose() }
    $gp.Dispose()
}

function Register-Rounded($Ctl, [int]$Radius) {
    $Ctl.Tag = @{ R = $Radius }
    $Ctl.Add_Resize({ param($s, $e) Set-Rounded $s $s.Tag.R })
    Set-Rounded $Ctl $Radius
}

function New-Label([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H, $Font, $Fore, $Back) {
    $l = New-Ctl 'Label' $X $Y $W $H $Text
    $l.Font = $Font; $l.ForeColor = $Fore; $l.BackColor = $Back; $l.AutoEllipsis = $true
    $l
}

function Set-ButtonColor($Btn, $Back) {
    $Btn.BackColor = $Back
    $Btn.ForeColor = Get-ContrastText $Back
    $Btn.FlatAppearance.MouseOverBackColor = Get-Mix $Back ([System.Drawing.Color]::White) 0.14
    $Btn.FlatAppearance.MouseDownBackColor = Get-Mix $Back ([System.Drawing.Color]::Black) 0.18
}

function New-FlatButton([string]$Text, [int]$X, [int]$Y, [int]$W, [int]$H, $Back, [int]$Radius = 10, $Font = $script:FontSemi) {
    $b = New-Ctl 'Button' $X $Y $W $H $Text
    $b.FlatStyle = 'Flat'; $b.FlatAppearance.BorderSize = 0; $b.UseVisualStyleBackColor = $false
    $b.Cursor = 'Hand'; $b.Font = $Font
    Set-ButtonColor $b $Back
    Register-Rounded $b $Radius
    $b
}

function New-Card([int]$X, [int]$Y, [int]$W, [int]$H) {
    $p = New-Ctl 'Panel' $X $Y $W $H
    $p.BackColor = $script:UI.Card
    Register-Rounded $p 14
    $p
}

function Set-DarkTitleBar($Frm) {
    try { $v = 1; [void][BrandyNative]::DwmSetWindowAttribute($Frm.Handle, 20, [ref]$v, 4) } catch { }
}

function Get-SelectedBrand { $script:lbBrand.SelectedItem }

function Update-WallPreview {
    $b = Get-SelectedBrand; if (-not $b) { return }
    $old = $script:pbWall.Image
    $script:pbWall.Image = New-BrandBitmap $b 640 360 'Wallpaper' $script:WallIdx
    if ($old) { $old.Dispose() }
    $script:lblWallCount.Text = "{0} / {1}" -f ($script:WallIdx + 1), $script:VariantCount
}

function Update-LockPreview {
    $b = Get-SelectedBrand; if (-not $b) { return }
    $old = $script:pbLock.Image
    $script:pbLock.Image = New-BrandBitmap $b 640 360 'Lock' $script:LockIdx
    if ($old) { $old.Dispose() }
    $script:lblLockCount.Text = "{0} / {1}" -f ($script:LockIdx + 1), $script:VariantCount
}

function Update-IconPreview {
    $b = Get-SelectedBrand; if (-not $b) { return }
    foreach ($pb in $script:flowIcons.Controls) {
        $old = $pb.Image
        $pb.Image = New-BrandIconBitmap $pb.Tag $b 256
        if ($old) { $old.Dispose() }
    }
}

function Update-Brand {
    $b = Get-SelectedBrand
    if (-not $b) { return }
    $changed = ($script:CurrentBrand -ne $b.Name)
    $script:CurrentBrand = $b.Name
    if ($changed) { $script:WallIdx = 0; $script:LockIdx = 0 }
    $pri = ConvertTo-Color $b.Primary
    $script:lblBrand.Text = $b.Name
    $script:lblBrand.ForeColor = Get-Mix $pri ([System.Drawing.Color]::White) 0.3
    $script:lblMeta.Text = $b.Category
    Set-ButtonColor $script:btnApply $pri
    $script:form.Cursor = 'WaitCursor'
    try {
        if ($changed) { Update-IconPreview }
        Update-WallPreview
        Update-LockPreview
    } finally { $script:form.Cursor = 'Default' }
    $script:lbBrand.Invalidate()
}

function Update-BrandList {
    $q = $script:txtSearch.Text.Trim()
    $prev = Get-SelectedBrand
    $script:Rebuilding = $true
    $script:lbBrand.BeginUpdate()
    $script:lbBrand.Items.Clear()
    foreach ($b in $script:Brands) {
        if (-not $q -or $b.Name.IndexOf($q, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or $b.Category.IndexOf($q, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            [void]$script:lbBrand.Items.Add($b)
        }
    }
    $script:lbBrand.EndUpdate()
    $script:Rebuilding = $false
    if ($script:lbBrand.Items.Count -gt 0) {
        $i = 0
        if ($prev) { $idx = $script:lbBrand.Items.IndexOf($prev); if ($idx -ge 0) { $i = $idx } }
        $script:lbBrand.SelectedIndex = $i
        Update-Brand
    } else {
        $script:lblBrand.Text = 'No match'; $script:lblMeta.Text = ''
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
        [void][System.Windows.Forms.MessageBox]::Show('Choose at least one item to apply.', $script:AppName, 'OK', 'Information'); return
    }
    $script:form.Enabled = $false; $script:form.Cursor = 'WaitCursor'
    try {
        $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $wv = $script:WallIdx; $lv = $script:LockIdx
        Write-Log "Applying..."
        $icons = $null
        if ($script:cbIcons.Checked -or $script:cbDesk.Checked -or $script:cbStart.Checked) {
            Invoke-Step 'Generate icon set' { $script:icons = Build-BrandIcons $brand }
            $icons = $script:icons
        }
        if ($script:cbWall.Checked)   { Invoke-Step 'Desktop wallpaper'  { Set-BrandWallpaper $brand $b.Width $b.Height $wv } }
        if ($script:cbLock.Checked)   { Invoke-Step 'Lock screen'        { Set-BrandLockScreen $brand $b.Width $b.Height $lv } }
        if ($script:cbAccent.Checked) { Invoke-Step 'Accent colour'      { Set-BrandAccent $brand $script:cbDark.Checked } }
        elseif ($script:cbDark.Checked) { Invoke-Step 'Dark mode'        { Set-DarkModeOnly } }
        if ($icons) {
            if ($script:cbIcons.Checked) { Invoke-Step 'File, folder, drive and app icons' { Set-ShellIcons $icons } }
            if ($script:cbDesk.Checked)  { Invoke-Step 'Desktop system icons'              { Set-DesktopIcons $icons } }
            if ($script:cbStart.Checked) { Invoke-Step 'Start menu folder icons'           { Set-StartFolderIcons $icons } }
        }
        Write-State
        Invoke-Step 'Refresh shell' { Update-ShellIcons }
        Write-Log "Applied. Sign out and back in to see every icon and colour."
    } finally { $script:form.Enabled = $true; $script:form.Cursor = 'Default' }
}

function Show-LogViewer {
    $f = New-Ctl 'Form' 0 0 640 420
    $f.Text = 'Activity log'; $f.StartPosition = 'CenterParent'; $f.BackColor = $script:UI.Bg; $f.ShowIcon = $false
    $t = New-Ctl 'TextBox' 12 12 616 396
    $t.Multiline = $true; $t.ReadOnly = $true; $t.ScrollBars = 'Vertical'; $t.BorderStyle = 'None'
    $t.BackColor = $script:UI.Card; $t.ForeColor = $script:UI.Text; $t.Font = New-Object System.Drawing.Font('Consolas', 9.5)
    $t.Anchor = 'Top,Bottom,Left,Right'
    $t.Text = ($script:LogLines -join "`r`n")
    $f.Controls.Add($t)
    $f.Add_Shown({ Set-DarkTitleBar $this })
    [void]$f.ShowDialog($script:form); $f.Dispose()
}

function Show-About {
    $f = New-Ctl 'Form' 0 0 440 330
    $f.Text = "About $($script:AppName)"
    $f.FormBorderStyle = 'FixedDialog'; $f.MaximizeBox = $false; $f.MinimizeBox = $false; $f.StartPosition = 'CenterParent'
    $f.ClientSize = New-Object System.Drawing.Size(440, 330)
    $f.BackColor = $script:UI.Bg; $f.ShowIcon = $false
    $bg = $script:UI.Bg; $tx = $script:UI.Text; $sb = $script:UI.Sub
    $pb = New-Ctl 'PictureBox' 24 24 72 72; $pb.SizeMode = 'Zoom'; $pb.Image = New-AppIconBitmap 144; $pb.BackColor = $bg
    $t  = New-Label $script:AppName 112 26 300 36 $script:FontBig $tx $bg
    $v  = New-Label "Version $($script:AppVersion)" 114 66 300 20 $script:FontReg $sb $bg
    $a  = New-Label "Created by $($script:Author)" 24 118 390 22 $script:FontSemi $tx $bg
    $e  = New-Ctl 'LinkLabel' 24 146 390 20 "Contact: $($script:Email)"
    $gh = New-Ctl 'LinkLabel' 24 170 390 20 "GitHub: $($script:GitHubUrl)"
    $e.Tag = "mailto:$($script:Email)"; $gh.Tag = $script:GitHubUrl
    foreach ($l in $e, $gh) {
        $l.BackColor = $bg; $l.LinkColor = Get-Mix (ConvertTo-Color '#4F8CFF') ([System.Drawing.Color]::White) 0.2; $l.ActiveLinkColor = [System.Drawing.Color]::White
        $l.Font = $script:FontReg
        $l.Add_LinkClicked({ param($s, $ev) Start-Process $s.Tag })
    }
    $d  = New-Label 'Brand names are trademarks of their respective owners. BrandyTheme is independent and not affiliated with them.' 24 206 392 52 $script:FontSub $sb $bg
    $ok = New-FlatButton 'Close' 316 272 100 38 (ConvertTo-Color '#2D6BFF')
    $ok.DialogResult = 'OK'; $f.AcceptButton = $ok
    $f.Controls.AddRange(@($pb, $t, $v, $a, $e, $gh, $d, $ok))
    $f.Add_Shown({ Set-DarkTitleBar $this })
    [void]$f.ShowDialog($script:form)
    $pb.Image.Dispose(); $f.Dispose()
}

# ------------------------------------------------------------------ main window
try {
    [System.Windows.Forms.Application]::EnableVisualStyles()
    $ui = $script:UI
    if (-not (Test-Path -LiteralPath $script:IconPath)) { $ib = New-AppIconBitmap 256; Save-Ico $ib $script:IconPath; $ib.Dispose() }

    $script:form = New-Object System.Windows.Forms.Form
    $form = $script:form
    $form.Text = $script:AppName
    $form.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $form.AutoScaleMode = 'Dpi'
    $form.Font = $script:FontReg
    $form.BackColor = $ui.Bg; $form.ForeColor = $ui.Text
    $form.ClientSize = New-Object System.Drawing.Size(1120, 716)
    $form.StartPosition = 'CenterScreen'
    $form.FormBorderStyle = 'FixedSingle'; $form.MaximizeBox = $false
    Set-DoubleBuffer $form
    # Taskbar fix #2: use the real BrandyTheme icon for the window / taskbar button
    try { $form.Icon = New-Object System.Drawing.Icon($script:IconPath) }
    catch { $tmpBmp = New-AppIconBitmap 64; $form.Icon = [System.Drawing.Icon]::FromHandle($tmpBmp.GetHicon()) }

    $script:Rebuilding = $false; $script:CurrentBrand = ''; $script:WallIdx = 0; $script:LockIdx = 0

    # ---- sidebar
    $side = New-Ctl 'Panel' 0 0 264 716; $side.BackColor = $ui.Side
    $pbLogo = New-Ctl 'PictureBox' 18 16 38 38; $pbLogo.SizeMode = 'Zoom'; $pbLogo.BackColor = $ui.Side; $pbLogo.Image = New-AppIconBitmap 96
    $lblApp = New-Label $script:AppName 64 14 190 24 $script:FontApp $ui.Text $ui.Side
    $lblVer = New-Label ("Version {0}" -f $script:AppVersion) 65 38 190 16 $script:FontSub $ui.Sub $ui.Side
    $searchHost = New-Ctl 'Panel' 16 68 232 34; $searchHost.BackColor = $ui.Card; Register-Rounded $searchHost 10
    $script:txtSearch = New-Ctl 'TextBox' 12 8 208 20
    $script:txtSearch.BorderStyle = 'None'; $script:txtSearch.BackColor = $ui.Card; $script:txtSearch.ForeColor = $ui.Text; $script:txtSearch.Font = $script:FontReg
    $searchHost.Controls.Add($script:txtSearch)

    $script:lbBrand = New-Ctl 'ListBox' 8 112 248 540
    $lb = $script:lbBrand
    $lb.DrawMode = 'OwnerDrawFixed'; $lb.ItemHeight = 48; $lb.BorderStyle = 'None'; $lb.BackColor = $ui.Side; $lb.IntegralHeight = $false
    Set-DoubleBuffer $lb
    $lb.Add_DrawItem({
        param($s, $e)
        if ($e.Index -lt 0) { return }
        $br = $s.Items[$e.Index]
        $g = $e.Graphics; $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'ClearTypeGridFit'
        $bg = New-SolidBrush $script:UI.Side; $g.FillRectangle($bg, $e.Bounds); $bg.Dispose()
        $pri = ConvertTo-Color $br.Primary; $sec = ConvertTo-Color $br.Secondary
        $selected = $e.State.HasFlag([System.Windows.Forms.DrawItemState]::Selected)
        $x = $e.Bounds.X + 6; $y = $e.Bounds.Y + 3; $w = $e.Bounds.Width - 12; $h = $e.Bounds.Height - 6
        if ($selected) {
            $path = New-RoundRect $x $y $w $h 10
            $sel = New-SolidBrush $script:UI.Card2; $g.FillPath($sel, $path); $sel.Dispose()
            $bar = New-SolidBrush $pri; $g.FillRectangle($bar, [single]($x), [single]($y + 12), [single]3, [single]($h - 24)); $bar.Dispose(); $path.Dispose()
        }
        $dot = New-Object System.Drawing.Drawing2D.LinearGradientBrush((New-Object System.Drawing.Rectangle(($x + 12), ($y + 7), 28, 28)), $pri, $sec, 45.0)
        $g.FillEllipse($dot, ($x + 12), ($y + 7), 28, 28); $dot.Dispose()
        $fmt = New-Object System.Drawing.StringFormat; $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
        $ib = New-SolidBrush (Get-ContrastText $pri)
        $g.DrawString($br.Name.Substring(0, 1), $script:FontSub, $ib, (New-Object System.Drawing.RectangleF(($x + 12), ($y + 7), 28, 28)), $fmt); $ib.Dispose()
        $tb = New-SolidBrush $script:UI.Text; $sb = New-SolidBrush $script:UI.Sub
        $g.DrawString($br.Name, $script:FontSemi, $tb, [single]($x + 50), [single]($y + 3))
        $g.DrawString($br.Category, $script:FontSub, $sb, [single]($x + 50), [single]($y + 22))
        $tb.Dispose(); $sb.Dispose()
    })
    $lb.Add_SelectedIndexChanged({ if (-not $script:Rebuilding) { Update-Brand } })
    $script:txtSearch.Add_TextChanged({ Update-BrandList })

    $btnShuffle = New-FlatButton 'Random theme' 16 664 232 40 $ui.Card2 12
    $btnShuffle.ForeColor = $ui.Text
    $btnShuffle.Add_Click({
        if ($script:lbBrand.Items.Count -gt 0) {
            $script:lbBrand.SelectedIndex = Get-Random -Maximum $script:lbBrand.Items.Count
            $script:WallIdx = Get-Random -Maximum $script:VariantCount
            $script:LockIdx = Get-Random -Maximum $script:VariantCount
            Update-WallPreview; Update-LockPreview
        }
    })
    $side.Controls.AddRange(@($pbLogo, $lblApp, $lblVer, $searchHost, $lb, $btnShuffle))

    # ---- header
    $script:lblBrand = New-Label '' 288 16 520 42 $script:FontBig $ui.Text $ui.Bg
    $script:lblMeta  = New-Label '' 291 58 540 20 $script:FontReg $ui.Sub $ui.Bg
    $btnAbout = New-FlatButton 'About'   842 20 86 34 $ui.Card 10 $script:FontReg
    $btnUpd   = New-FlatButton 'Updates' 936 20 108 34 $ui.Card 10 $script:FontReg
    $btnMore  = New-FlatButton '•••'     1052 20 44 34 $ui.Card 10 $script:FontReg
    foreach ($hb in $btnAbout, $btnUpd, $btnMore) { $hb.ForeColor = $ui.Text; $hb.FlatAppearance.MouseOverBackColor = $ui.Card2 }

    # ---- preview cards
    function New-PreviewCard([int]$X, [string]$Title, [string]$Which) {
        $card = New-Card $X 92 396 296
        $t = New-Label $Title 16 12 200 22 $script:FontSemi $ui.Text $ui.Card
        $pb = New-Ctl 'PictureBox' 16 44 364 205; $pb.SizeMode = 'Zoom'; $pb.BackColor = $ui.Bg; Register-Rounded $pb 10
        $prev = New-FlatButton ([string][char]0x2039) 16 258 38 28 $ui.Card2 8 $script:FontSemi
        $cnt  = New-Label '' 60 262 70 20 $script:FontReg $ui.Sub $ui.Card; $cnt.TextAlign = 'MiddleCenter'
        $next = New-FlatButton ([string][char]0x203A) 136 258 38 28 $ui.Card2 8 $script:FontSemi
        $shuf = New-FlatButton 'Shuffle' 292 258 88 28 $ui.Card2 8 $script:FontSub
        foreach ($bb in $prev, $next, $shuf) { $bb.ForeColor = $ui.Text }
        $card.Controls.AddRange(@($t, $pb, $prev, $cnt, $next, $shuf))
        if ($Which -eq 'Wall') {
            $script:pbWall = $pb; $script:lblWallCount = $cnt
            $prev.Add_Click({ $script:WallIdx = ($script:WallIdx + $script:VariantCount - 1) % $script:VariantCount; Update-WallPreview })
            $next.Add_Click({ $script:WallIdx = ($script:WallIdx + 1) % $script:VariantCount; Update-WallPreview })
            $shuf.Add_Click({ $script:WallIdx = Get-Random -Maximum $script:VariantCount; Update-WallPreview })
        } else {
            $script:pbLock = $pb; $script:lblLockCount = $cnt
            $prev.Add_Click({ $script:LockIdx = ($script:LockIdx + $script:VariantCount - 1) % $script:VariantCount; Update-LockPreview })
            $next.Add_Click({ $script:LockIdx = ($script:LockIdx + 1) % $script:VariantCount; Update-LockPreview })
            $shuf.Add_Click({ $script:LockIdx = Get-Random -Maximum $script:VariantCount; Update-LockPreview })
        }
        $card
    }
    $cardWall = New-PreviewCard 288 'Wallpaper' 'Wall'
    $cardLock = New-PreviewCard 700 'Lock screen' 'Lock'

    # ---- icon card
    $cardIcons = New-Card 288 404 808 100
    $cardIcons.Controls.Add((New-Label 'Icons' 16 10 200 22 $script:FontSemi $ui.Text $ui.Card))
    $script:flowIcons = New-Ctl 'FlowLayoutPanel' 12 36 784 58
    $script:flowIcons.BackColor = $ui.Card
    foreach ($k in 'Folder', 'FolderOpen', 'File', 'App', 'Drive', 'Disc', 'Pc', 'Recycle', 'Network', 'User', 'Control') {
        $ipb = New-Ctl 'PictureBox' 0 0 54 54
        $ipb.SizeMode = 'Zoom'; $ipb.Tag = $k; $ipb.BackColor = $ui.Card; $ipb.Margin = New-Object System.Windows.Forms.Padding(2, 2, 12, 2)
        $script:flowIcons.Controls.Add($ipb)
    }
    $cardIcons.Controls.Add($script:flowIcons)

    # ---- options card
    $cardOpt = New-Card 288 524 808 112
    function New-Option([string]$Text, [int]$X, [int]$Y, [bool]$On) {
        $c = New-Ctl 'CheckBox' $X $Y 370 24 $Text
        $c.Checked = $On; $c.BackColor = $ui.Card; $c.ForeColor = $ui.Text; $c.Font = $script:FontReg; $c.Cursor = 'Hand'
        $c
    }
    $script:cbWall   = New-Option 'Wallpaper' 20 10 $true
    $script:cbLock   = New-Option 'Lock screen' 20 36 $true
    $script:cbAccent = New-Option 'Accent colour' 20 62 $true
    $script:cbDark   = New-Option 'Dark mode' 20 86 $false
    $script:cbIcons  = New-Option 'File, folder and drive icons' 420 10 $true
    $script:cbDesk   = New-Option 'Desktop icons' 420 36 $true
    $script:cbStart  = New-Option 'Start menu icons' 420 62 $true
    $cardOpt.Controls.AddRange(@($script:cbWall, $script:cbLock, $script:cbAccent, $script:cbDark, $script:cbIcons, $script:cbDesk, $script:cbStart))

    # ---- actions
    $script:btnApply = New-FlatButton 'Apply theme' 288 652 230 46 (ConvertTo-Color '#2D6BFF') 12 $script:FontApp
    $btnRestore = New-FlatButton 'Restore defaults' 530 652 210 46 $ui.Card2 12
    $btnRestore.ForeColor = $ui.Text
    $script:lblStatus = New-Label '' 756 652 340 46 $script:FontSub $ui.Sub $ui.Bg
    $script:lblStatus.TextAlign = 'MiddleLeft'; $script:lblStatus.AutoEllipsis = $false

    $script:btnApply.Add_Click({ Invoke-Apply })
    $btnRestore.Add_Click({
        $a = [System.Windows.Forms.MessageBox]::Show('Revert everything BrandyTheme changed back to your original settings?', $script:AppName, 'YesNo', 'Question')
        if ($a -eq 'Yes') { $script:form.Enabled = $false; try { Restore-All } finally { $script:form.Enabled = $true } }
    })

    # ---- "more" menu (dark)
    $ctx = New-Object System.Windows.Forms.ContextMenuStrip
    try {
        if (-not ('BrandyDarkTable' -as [type])) {
            Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @'
using System.Drawing;
using System.Windows.Forms;
public class BrandyDarkTable : ProfessionalColorTable {
    static Color Bg = Color.FromArgb(26, 29, 37), Hover = Color.FromArgb(44, 49, 62), Line = Color.FromArgb(52, 57, 70);
    public override Color ToolStripDropDownBackground { get { return Bg; } }
    public override Color ImageMarginGradientBegin { get { return Bg; } }
    public override Color ImageMarginGradientMiddle { get { return Bg; } }
    public override Color ImageMarginGradientEnd { get { return Bg; } }
    public override Color MenuBorder { get { return Line; } }
    public override Color MenuItemBorder { get { return Hover; } }
    public override Color MenuItemSelected { get { return Hover; } }
    public override Color MenuItemSelectedGradientBegin { get { return Hover; } }
    public override Color MenuItemSelectedGradientEnd { get { return Hover; } }
    public override Color SeparatorDark { get { return Line; } }
    public override Color SeparatorLight { get { return Line; } }
    public override Color CheckBackground { get { return Hover; } }
    public override Color CheckSelectedBackground { get { return Hover; } }
    public override Color CheckPressedBackground { get { return Hover; } }
}
'@
        }
        $ctx.Renderer = New-Object System.Windows.Forms.ToolStripProfessionalRenderer (New-Object BrandyDarkTable)
    } catch { }
    $ctx.BackColor = $ui.Card; $ctx.ForeColor = $ui.Text; $ctx.Font = $script:FontReg
    $mAuto = New-Object System.Windows.Forms.ToolStripMenuItem('Check for updates on start')
    $mAuto.CheckOnClick = $true; $mAuto.Checked = [bool]$script:Settings.AutoUpdate
    $mAuto.Add_CheckedChanged({ $script:Settings.AutoUpdate = $mAuto.Checked; Write-Settings })
    $mLog  = New-Object System.Windows.Forms.ToolStripMenuItem('View activity log')
    $mData = New-Object System.Windows.Forms.ToolStripMenuItem('Open data folder')
    $mWeb  = New-Object System.Windows.Forms.ToolStripMenuItem('GitHub repository')
    $mLog.Add_Click({ Show-LogViewer })
    $mData.Add_Click({ Start-Process explorer.exe $script:DataDir })
    $mWeb.Add_Click({ Start-Process $script:GitHubUrl })
    foreach ($mi in $mAuto, $mLog, $mData, $mWeb) { $mi.ForeColor = $ui.Text; $mi.BackColor = $ui.Card }
    [void]$ctx.Items.AddRange(@($mAuto, (New-Object System.Windows.Forms.ToolStripSeparator), $mLog, $mData, $mWeb))

    $btnAbout.Add_Click({ Show-About })
    $btnUpd.Add_Click({ Invoke-UpdateCheck $false })
    $btnMore.Add_Click({ $ctx.Show($btnMore, (New-Object System.Drawing.Point(($btnMore.Width - 230), $btnMore.Height + 6))) })

    $form.Controls.AddRange(@($side, $script:lblBrand, $script:lblMeta, $btnAbout, $btnUpd, $btnMore, $cardWall, $cardLock, $cardIcons, $cardOpt,
                              $script:btnApply, $btnRestore, $script:lblStatus))

    $form.Add_Shown({
        Set-DarkTitleBar $script:form
        try { [void][BrandyNative]::SendMessage($script:txtSearch.Handle, 0x1501, [IntPtr]1, 'Search') } catch { }
        Update-BrandList
        if ($script:Settings.AutoUpdate -and -not $NoUpdateCheck) { Invoke-UpdateCheck $true }
    })

    [System.Windows.Forms.Application]::Run($form)
} catch {
    [void][System.Windows.Forms.MessageBox]::Show("BrandyTheme hit an unexpected error:`r`n`r`n$($_.Exception.Message)", $script:AppName, 'OK', 'Error')
    exit 1
}
