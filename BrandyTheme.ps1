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
$script:AppVersion  = '1.3.3'
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
$script:txtStatus    = $null
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
    $g.SmoothingMode = 'AntiAlias'
    $g.ScaleTransform($Size / 256.0, $Size / 256.0)
    $PF = [System.Drawing.PointF]
    $gb = New-Object System.Drawing.Drawing2D.LinearGradientBrush($PF::new(20, 0), $PF::new(236, 256), (ConvertTo-Color '#4C8DFF'), (ConvertTo-Color '#8B5CF6'))
    $g.FillPath($gb, (New-RoundRect 6 6 244 244 58))
    $gb.Dispose()
    # three stacked layers = "theme"
    $layer2 = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(115, 255, 255, 255), 16)
    $layer1 = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(205, 255, 255, 255), 16)
    foreach ($p in $layer1, $layer2) { $p.StartCap = 'Round'; $p.EndCap = 'Round'; $p.LineJoin = 'Round' }
    $g.DrawLines($layer2, (New-Pts 56, 168, 128, 206, 200, 168))
    $g.DrawLines($layer1, (New-Pts 56, 136, 128, 174, 200, 136))
    $top = New-Pts 128, 50, 204, 92, 128, 134, 52, 92
    $g.FillPolygon([System.Drawing.Brushes]::White, $top)
    $edge = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 12); $edge.LineJoin = 'Round'
    $g.DrawPolygon($edge, $top)
    $layer1.Dispose(); $layer2.Dispose(); $edge.Dispose()
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
    $script:LogLines.Add(("[{0:HH:mm:ss}] {1}" -f (Get-Date), $Message))
    if ($script:txtStatus) { $script:txtStatus.Text = $Message; Update-UI }
    else { Write-Host $Message }
}

# Diagnostics: any problem is written to error.log and shown, instead of the app silently closing
$script:ShowingError = $false
function Write-Trace([string]$Message) {
    try { Add-Content -LiteralPath (Join-Path $script:DataDir 'app.log') -Value ("[{0:HH:mm:ss}] {1}" -f (Get-Date), $Message) -Encoding UTF8 } catch { }
}
function Write-AppError($ErrorObject, [string]$Where = '') {
    $detail = ''
    if ($ErrorObject -is [System.Management.Automation.ErrorRecord]) {
        $short = $ErrorObject.Exception.Message
        $detail = "$short`r`n$($ErrorObject.InvocationInfo.PositionMessage)`r`n$($ErrorObject.ScriptStackTrace)"
    } elseif ($ErrorObject -is [Exception]) {
        $short = $ErrorObject.Message; $detail = $ErrorObject.ToString()
    } else { $short = "$ErrorObject"; $detail = $short }
    $logFile = Join-Path $script:DataDir 'error.log'
    try { Add-Content -LiteralPath $logFile -Value ("[{0:u}] {1} v{2}`r`n{3}`r`n" -f (Get-Date), $Where, $script:AppVersion, $detail) -Encoding UTF8 } catch { }
    $script:LogLines.Add("ERROR ($Where): $short")
    if ($script:txtStatus) { try { $script:txtStatus.Text = "Something went wrong ($Where). See error.log in the data folder." } catch { } }
    if (-not $script:ShowingError) {
        $script:ShowingError = $true
        try { [void][System.Windows.Forms.MessageBox]::Show("BrandyTheme ran into a problem ($Where):`r`n`r`n$short`r`n`r`nDetails were saved to:`r`n$logFile", $script:AppName, 'OK', 'Warning') }
        finally { $script:ShowingError = $false }
    }
}
function Invoke-Safe([scriptblock]$Action, [string]$Where = 'action') {
    try { & $Action } catch { Write-AppError $_ $Where }
}
trap { Write-AppError $_ 'startup'; exit 1 }

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

# ------------------------------------------------------------------ WPF (modern UI)
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

function ConvertTo-BitmapSource($Bitmap) {
    $ms = New-Object System.IO.MemoryStream
    $Bitmap.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $ms.Position = 0
    $bi = New-Object System.Windows.Media.Imaging.BitmapImage
    $bi.BeginInit(); $bi.CacheOption = 'OnLoad'; $bi.StreamSource = $ms; $bi.EndInit(); $bi.Freeze()
    $ms.Dispose()
    $bi
}

function Set-AppResource([string]$Key, $Value) {
    if ($Value -is [System.Management.Automation.PSObject]) { $Value = $Value.psobject.BaseObject }
    $script:win.Resources[$Key] = $Value
}

function ConvertTo-MediaColor([System.Drawing.Color]$C) { [System.Windows.Media.Color]::FromRgb($C.R, $C.G, $C.B) }

# let the UI repaint during long operations
function Update-UI {
    try {
        $frame = New-Object System.Windows.Threading.DispatcherFrame
        $script:CurFrame = $frame
        [void][System.Windows.Threading.Dispatcher]::CurrentDispatcher.BeginInvoke(
            [System.Windows.Threading.DispatcherPriority]::Background,
            [System.Windows.Threading.DispatcherOperationCallback]{ param($o) $script:CurFrame.Continue = $false; $null }, $null)
        [System.Windows.Threading.Dispatcher]::PushFrame($frame)
    } catch { }
}

# dark title bar that blends into the window
function Set-WpfChrome($Win) {
    $Win.Add_SourceInitialized({
        param($s, $e)
        try {
            $h = (New-Object System.Windows.Interop.WindowInteropHelper($s)).Handle
            $v = 1;        [void][BrandyNative]::DwmSetWindowAttribute($h, 20, [ref]$v, 4)   # dark mode
            $cap = 0x120D0B; [void][BrandyNative]::DwmSetWindowAttribute($h, 35, [ref]$cap, 4) # caption colour (Win11)
            $txt = 0xF8F4F2; [void][BrandyNative]::DwmSetWindowAttribute($h, 36, [ref]$txt, 4) # caption text (Win11)
        } catch { }
    })
}

$script:ResXaml = @'
<SolidColorBrush x:Key="Bg" Color="#0B0D12"/>
<SolidColorBrush x:Key="Side" Color="#0F121A"/>
<SolidColorBrush x:Key="Card" Color="#151922"/>
<SolidColorBrush x:Key="Card2" Color="#1D222D"/>
<SolidColorBrush x:Key="Stroke" Color="#232835"/>
<SolidColorBrush x:Key="Text" Color="#F2F4F8"/>
<SolidColorBrush x:Key="Sub" Color="#8E96A8"/>
<Color x:Key="AccentColor">#3B82F6</Color>
<SolidColorBrush x:Key="Accent" Color="#3B82F6"/>
<SolidColorBrush x:Key="AccentFg" Color="#FFFFFF"/>
<FontFamily x:Key="IconFont">Segoe Fluent Icons, Segoe MDL2 Assets</FontFamily>

<Style x:Key="Solid" TargetType="Button">
  <Setter Property="Foreground" Value="{DynamicResource AccentFg}"/>
  <Setter Property="FontSize" Value="15"/><Setter Property="FontWeight" Value="SemiBold"/>
  <Setter Property="Cursor" Value="Hand"/><Setter Property="FocusVisualStyle" Value="{x:Null}"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
    <Border x:Name="Bd" Background="{DynamicResource Accent}" CornerRadius="14" Padding="22,0">
      <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
    </Border>
    <ControlTemplate.Triggers>
      <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Opacity" Value="0.88"/></Trigger>
      <Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Opacity" Value="0.74"/></Trigger>
      <Trigger Property="IsEnabled" Value="False"><Setter TargetName="Bd" Property="Opacity" Value="0.4"/></Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>

<Style x:Key="Soft" TargetType="Button">
  <Setter Property="Foreground" Value="{StaticResource Text}"/>
  <Setter Property="FontSize" Value="14"/><Setter Property="FontWeight" Value="SemiBold"/>
  <Setter Property="Cursor" Value="Hand"/><Setter Property="FocusVisualStyle" Value="{x:Null}"/>
  <Setter Property="HorizontalContentAlignment" Value="Center"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
    <Border x:Name="Bd" Background="{StaticResource Card2}" CornerRadius="14" Padding="20,0">
      <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
    </Border>
    <ControlTemplate.Triggers>
      <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#283040"/></Trigger>
      <Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Background" Value="#313A4D"/></Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>

<Style x:Key="Ghost" TargetType="Button">
  <Setter Property="Foreground" Value="{StaticResource Text}"/>
  <Setter Property="FontSize" Value="14"/><Setter Property="Padding" Value="14,0"/>
  <Setter Property="Cursor" Value="Hand"/><Setter Property="FocusVisualStyle" Value="{x:Null}"/>
  <Setter Property="HorizontalContentAlignment" Value="Center"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
    <Border x:Name="Bd" Background="Transparent" CornerRadius="10" Padding="{TemplateBinding Padding}">
      <ContentPresenter HorizontalAlignment="{TemplateBinding HorizontalContentAlignment}" VerticalAlignment="Center"/>
    </Border>
    <ControlTemplate.Triggers>
      <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="{StaticResource Card2}"/></Trigger>
      <Trigger Property="IsPressed" Value="True"><Setter TargetName="Bd" Property="Background" Value="#283040"/></Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>

<Style x:Key="IconBtn" TargetType="Button" BasedOn="{StaticResource Ghost}">
  <Setter Property="FontFamily" Value="{StaticResource IconFont}"/>
  <Setter Property="FontSize" Value="16"/><Setter Property="Padding" Value="0"/>
  <Setter Property="Width" Value="38"/><Setter Property="Height" Value="38"/>
</Style>

<Style x:Key="Round" TargetType="Button">
  <Setter Property="FontFamily" Value="{StaticResource IconFont}"/>
  <Setter Property="FontSize" Value="14"/><Setter Property="Foreground" Value="White"/>
  <Setter Property="Width" Value="36"/><Setter Property="Height" Value="36"/>
  <Setter Property="Cursor" Value="Hand"/><Setter Property="FocusVisualStyle" Value="{x:Null}"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button">
    <Border x:Name="Bd" Background="#8C000000" CornerRadius="18">
      <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
    </Border>
    <ControlTemplate.Triggers>
      <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#D9000000"/></Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>

<Style x:Key="Switch" TargetType="ToggleButton">
  <Setter Property="Foreground" Value="{StaticResource Text}"/>
  <Setter Property="FontSize" Value="14"/>
  <Setter Property="Cursor" Value="Hand"/><Setter Property="FocusVisualStyle" Value="{x:Null}"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ToggleButton">
    <StackPanel Orientation="Horizontal" Background="Transparent">
      <Grid Width="40" Height="22" VerticalAlignment="Center">
        <Border x:Name="Track" CornerRadius="11" Background="#2C3340"/>
        <Ellipse x:Name="Thumb" Width="16" Height="16" Fill="#C5CBD8" HorizontalAlignment="Left" Margin="3,0,0,0"/>
      </Grid>
      <ContentPresenter Margin="12,0,0,0" VerticalAlignment="Center"/>
    </StackPanel>
    <ControlTemplate.Triggers>
      <Trigger Property="IsChecked" Value="True">
        <Setter TargetName="Track" Property="Background" Value="{DynamicResource Accent}"/>
        <Setter TargetName="Thumb" Property="HorizontalAlignment" Value="Right"/>
        <Setter TargetName="Thumb" Property="Margin" Value="0,0,3,0"/>
        <Setter TargetName="Thumb" Property="Fill" Value="{DynamicResource AccentFg}"/>
      </Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>

<Style x:Key="Search" TargetType="TextBox">
  <Setter Property="Foreground" Value="{StaticResource Text}"/><Setter Property="CaretBrush" Value="{StaticResource Text}"/>
  <Setter Property="FontSize" Value="14"/><Setter Property="Height" Value="42"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="TextBox">
    <Border x:Name="Bd" Background="{StaticResource Card}" BorderBrush="{StaticResource Stroke}" BorderThickness="1" CornerRadius="12">
      <Grid>
        <TextBlock x:Name="Hint" Text="Search brands" Foreground="{StaticResource Sub}" Margin="14,0,0,0" VerticalAlignment="Center" IsHitTestVisible="False" Visibility="Collapsed"/>
        <ScrollViewer x:Name="PART_ContentHost" Margin="12,0" VerticalAlignment="Center"/>
      </Grid>
    </Border>
    <ControlTemplate.Triggers>
      <Trigger Property="Text" Value=""><Setter TargetName="Hint" Property="Visibility" Value="Visible"/></Trigger>
      <Trigger Property="IsKeyboardFocused" Value="True"><Setter TargetName="Bd" Property="BorderBrush" Value="{DynamicResource Accent}"/></Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>

<Style x:Key="BrandItem" TargetType="ListBoxItem">
  <Setter Property="Padding" Value="10,0"/><Setter Property="Margin" Value="0,1"/>
  <Setter Property="Cursor" Value="Hand"/><Setter Property="FocusVisualStyle" Value="{x:Null}"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ListBoxItem">
    <Grid>
      <Border x:Name="Bd" CornerRadius="12" Background="Transparent"/>
      <Border x:Name="Bar" Width="3" Height="22" CornerRadius="2" HorizontalAlignment="Left" Margin="1,0,0,0" Background="{DynamicResource Accent}" Visibility="Collapsed"/>
      <ContentPresenter Margin="{TemplateBinding Padding}" VerticalAlignment="Center"/>
    </Grid>
    <ControlTemplate.Triggers>
      <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Bd" Property="Background" Value="#151922"/></Trigger>
      <Trigger Property="IsSelected" Value="True">
        <Setter TargetName="Bd" Property="Background" Value="#1D222D"/>
        <Setter TargetName="Bar" Property="Visibility" Value="Visible"/>
      </Trigger>
    </ControlTemplate.Triggers>
  </ControlTemplate></Setter.Value></Setter>
</Style>

<Style TargetType="ListBox">
  <Setter Property="Background" Value="Transparent"/><Setter Property="BorderThickness" Value="0"/>
  <Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Disabled"/>
  <Setter Property="Foreground" Value="{StaticResource Text}"/>
</Style>

<Style TargetType="ScrollBar">
  <Setter Property="Width" Value="8"/><Setter Property="Background" Value="Transparent"/>
  <Setter Property="Template"><Setter.Value><ControlTemplate TargetType="ScrollBar">
    <Track x:Name="PART_Track" IsDirectionReversed="True">
      <Track.DecreaseRepeatButton><RepeatButton Command="ScrollBar.PageUpCommand" Opacity="0" Focusable="False"/></Track.DecreaseRepeatButton>
      <Track.Thumb><Thumb><Thumb.Template><ControlTemplate TargetType="Thumb"><Border CornerRadius="4" Background="#363D4D" Margin="1"/></ControlTemplate></Thumb.Template></Thumb></Track.Thumb>
      <Track.IncreaseRepeatButton><RepeatButton Command="ScrollBar.PageDownCommand" Opacity="0" Focusable="False"/></Track.IncreaseRepeatButton>
    </Track>
  </ControlTemplate></Setter.Value></Setter>
</Style>
'@

$script:WinHead = @'
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="14" UseLayoutRounding="True" SnapsToDevicePixels="True"
TextOptions.TextRenderingMode="ClearType"
'@

function ConvertFrom-Xaml([string]$Xaml) {
    [System.Windows.Markup.XamlReader]::Parse($Xaml.Replace('{{RES}}', $script:ResXaml).Replace('{{HEAD}}', $script:WinHead))
}

# ------------------------------------------------------------------ dialogs
$script:DialogXaml = @'
<Window {{HEAD}} Title="BrandyTheme" Width="440" SizeToContent="Height" ResizeMode="NoResize" ShowInTaskbar="False"
        WindowStartupLocation="CenterOwner" Background="{DynamicResource Bg}" Foreground="{DynamicResource Text}">
  <Window.Resources>{{RES}}</Window.Resources>
  <Grid Margin="30,28,30,24">
    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
    <StackPanel>
      <TextBlock x:Name="T" FontSize="19" FontWeight="SemiBold" TextWrapping="Wrap"/>
      <TextBlock x:Name="M" FontSize="14" Foreground="#AAB2C3" TextWrapping="Wrap" Margin="0,10,0,0" LineHeight="21"/>
    </StackPanel>
    <StackPanel Grid.Row="1" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,26,0,0">
      <Button x:Name="B2" Style="{StaticResource Soft}" Height="40" MinWidth="96" Margin="0,0,10,0"/>
      <Button x:Name="B1" Style="{StaticResource Solid}" Height="40" MinWidth="96"/>
    </StackPanel>
  </Grid>
</Window>
'@

function Show-Dialog {
    param([string]$Title, [string]$Message, [string]$Primary = 'OK', [string]$Secondary = '')
    $w = ConvertFrom-Xaml $script:DialogXaml
    Set-WpfChrome $w
    $w.FindName('T').Text = $Title
    $w.FindName('M').Text = $Message
    $b1 = $w.FindName('B1'); $b2 = $w.FindName('B2')
    $b1.Content = $Primary
    if ($Secondary) { $b2.Content = $Secondary } else { $b2.Visibility = 'Collapsed' }
    $b1.Add_Click({ $w.DialogResult = $true }.GetNewClosure())
    $b2.Add_Click({ $w.DialogResult = $false }.GetNewClosure())
    if ($script:win -and $script:win.IsVisible) { $w.Owner = $script:win }
    $r = $w.ShowDialog()
    return ($r -eq $true)
}

$script:AboutXaml = @'
<Window {{HEAD}} Title="About BrandyTheme" Width="440" SizeToContent="Height" ResizeMode="NoResize" ShowInTaskbar="False"
        WindowStartupLocation="CenterOwner" Background="{DynamicResource Bg}" Foreground="{DynamicResource Text}">
  <Window.Resources>{{RES}}</Window.Resources>
  <StackPanel Margin="34,32,34,26">
    <StackPanel Orientation="Horizontal">
      <Image x:Name="Logo" Width="68" Height="68"/>
      <StackPanel Margin="18,0,0,0" VerticalAlignment="Center">
        <TextBlock Text="BrandyTheme" FontSize="26" FontWeight="SemiBold"/>
        <TextBlock x:Name="Ver" Foreground="{StaticResource Sub}" FontSize="13" Margin="0,2,0,0"/>
      </StackPanel>
    </StackPanel>
    <Border Height="1" Background="{StaticResource Stroke}" Margin="0,24,0,20"/>
    <TextBlock Text="Created by" Foreground="{StaticResource Sub}" FontSize="12"/>
    <TextBlock x:Name="Author" FontSize="16" FontWeight="SemiBold" Margin="0,2,0,14"/>
    <TextBlock Text="Contact" Foreground="{StaticResource Sub}" FontSize="12"/>
    <TextBlock x:Name="MailLink" FontSize="14" Foreground="#6EA8FF" Cursor="Hand" Margin="0,2,0,14"/>
    <TextBlock Text="GitHub" Foreground="{StaticResource Sub}" FontSize="12"/>
    <TextBlock x:Name="WebLink" FontSize="14" Foreground="#6EA8FF" Cursor="Hand" Margin="0,2,0,0"/>
    <TextBlock Text="Brand names are trademarks of their respective owners. BrandyTheme is independent and not affiliated with them."
               Foreground="{StaticResource Sub}" FontSize="12" TextWrapping="Wrap" Margin="0,22,0,0" LineHeight="18"/>
    <Button x:Name="CloseBtn" Style="{StaticResource Solid}" Content="Close" Height="40" Width="110" HorizontalAlignment="Right" Margin="0,22,0,0"/>
  </StackPanel>
</Window>
'@

function Show-About {
    $w = ConvertFrom-Xaml $script:AboutXaml
    Set-WpfChrome $w
    $bmp = New-AppIconBitmap 256; $w.FindName('Logo').Source = ConvertTo-BitmapSource $bmp; $bmp.Dispose()
    $w.FindName('Ver').Text = "Version $($script:AppVersion)"
    $w.FindName('Author').Text = $script:Author
    $mail = $w.FindName('MailLink'); $mail.Text = $script:Email
    $web  = $w.FindName('WebLink');  $web.Text = $script:GitHubUrl.Replace('https://', '')
    $mail.Add_MouseLeftButtonUp({ Start-Process "mailto:$($script:Email)" })
    $web.Add_MouseLeftButtonUp({ Start-Process $script:GitHubUrl })
    $w.FindName('CloseBtn').Add_Click({ $w.Close() }.GetNewClosure())
    if ($script:win -and $script:win.IsVisible) { $w.Owner = $script:win }
    [void]$w.ShowDialog()
}

$script:LogXaml = @'
<Window {{HEAD}} Title="Activity log" Width="620" Height="400" ShowInTaskbar="False" WindowStartupLocation="CenterOwner"
        Background="{DynamicResource Bg}" Foreground="{DynamicResource Text}">
  <Window.Resources>{{RES}}</Window.Resources>
  <Border Margin="16" Background="{StaticResource Card}" CornerRadius="14" Padding="14">
    <TextBox x:Name="Box" IsReadOnly="True" Background="Transparent" BorderThickness="0" Foreground="#C9D1E0"
             FontFamily="Cascadia Mono, Consolas" FontSize="13" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto"/>
  </Border>
</Window>
'@

function Show-LogViewer {
    $w = ConvertFrom-Xaml $script:LogXaml
    Set-WpfChrome $w
    $w.FindName('Box').Text = ($script:LogLines -join "`r`n")
    if ($script:win -and $script:win.IsVisible) { $w.Owner = $script:win }
    [void]$w.ShowDialog()
}

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
    $script:win.Close()
}

function Invoke-UpdateCheck([bool]$Silent) {
    try {
        [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
        $remote = Get-RemoteVersion
        $local = [version]$script:AppVersion
        [System.Windows.Input.Mouse]::OverrideCursor = $null
        if ($remote.Version -gt $local) {
            if (Show-Dialog 'Update available' "Version $($remote.Version) is ready. You have $local." 'Update now' 'Later') { Install-Update $remote }
        } elseif (-not $Silent) {
            [void](Show-Dialog 'You are up to date' "BrandyTheme $local is the latest version.")
        }
    } catch {
        [System.Windows.Input.Mouse]::OverrideCursor = $null
        if ($Silent) { Write-Log "Update check skipped: $($_.Exception.Message)" }
        else { [void](Show-Dialog 'Could not check for updates' $_.Exception.Message) }
    }
}

# ------------------------------------------------------------------ app logic
function Get-SelectedBrand { $i = $script:lbBrands.SelectedItem; if ($i) { $i.Tag } }

function New-BrandListItem($b) {
    $xaml = @"
<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Height="48">
  <Grid.ColumnDefinitions><ColumnDefinition Width="44"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
  <Ellipse Width="28" Height="28" HorizontalAlignment="Left" Margin="4,0,0,0">
    <Ellipse.Fill><LinearGradientBrush StartPoint="0,0" EndPoint="1,1"><GradientStop Color="$($b.Primary)" Offset="0.1"/><GradientStop Color="$($b.Secondary)" Offset="1"/></LinearGradientBrush></Ellipse.Fill>
  </Ellipse>
  <StackPanel Grid.Column="1" VerticalAlignment="Center">
    <TextBlock Text="$($b.Name)" FontSize="14" FontWeight="SemiBold" Foreground="#F2F4F8"/>
    <TextBlock Text="$($b.Category)" FontSize="12" Foreground="#8E96A8" Margin="0,1,0,0"/>
  </StackPanel>
</Grid>
"@
    $li = New-Object System.Windows.Controls.ListBoxItem
    $content = [System.Windows.Markup.XamlReader]::Parse($xaml)
    if ($content -is [System.Management.Automation.PSObject]) { $content = $content.psobject.BaseObject }
    $li.Content = $content
    $li.Tag = $b
    $st = $script:win.TryFindResource('BrandItem'); if ($st) { $li.Style = $st }
    $li
}

function Update-WallPreview {
    $b = Get-SelectedBrand; if (-not $b) { return }
    $bmp = New-BrandBitmap $b 800 450 'Wallpaper' $script:WallIdx
    try { $script:brushWall.ImageSource = ConvertTo-BitmapSource $bmp } finally { $bmp.Dispose() }
    $script:txtWallCount.Text = "{0} / {1}" -f ($script:WallIdx + 1), $script:VariantCount
}

function Update-LockPreview {
    $b = Get-SelectedBrand; if (-not $b) { return }
    $bmp = New-BrandBitmap $b 800 450 'Lock' $script:LockIdx
    try { $script:brushLock.ImageSource = ConvertTo-BitmapSource $bmp } finally { $bmp.Dispose() }
    $script:txtLockCount.Text = "{0} / {1}" -f ($script:LockIdx + 1), $script:VariantCount
}

function Update-IconPreview {
    $b = Get-SelectedBrand; if (-not $b) { return }
    foreach ($img in $script:iconImages) {
        $bmp = New-BrandIconBitmap $img.Tag $b 128
        try { $img.Source = ConvertTo-BitmapSource $bmp } finally { $bmp.Dispose() }
    }
}

function Update-Brand {
    $b = Get-SelectedBrand
    if (-not $b) { return }
    $changed = ($script:CurrentBrand -ne $b.Name)
    $script:CurrentBrand = $b.Name
    if ($changed) { $script:WallIdx = 0; $script:LockIdx = 0 }
    $script:txtBrand.Text = $b.Name
    $script:txtCat.Text = $b.Category
    $script:catPill.Visibility = 'Visible'
    $c = ConvertTo-Color $b.Primary
    $mc = ConvertTo-MediaColor $c
    $fgColor = ConvertTo-MediaColor (Get-ContrastText $c)
    Set-AppResource 'AccentColor' $mc
    Set-AppResource 'Accent'   ([System.Windows.Media.SolidColorBrush]::new($mc))
    Set-AppResource 'AccentFg' ([System.Windows.Media.SolidColorBrush]::new($fgColor))
    $script:lbBrands.ScrollIntoView($script:lbBrands.SelectedItem)
    [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
    try {
        if ($changed) { Update-IconPreview }
        Update-WallPreview
        Update-LockPreview
    } finally { [System.Windows.Input.Mouse]::OverrideCursor = $null }
}

function Update-BrandList {
    $q = $script:tbSearch.Text.Trim()
    $prev = Get-SelectedBrand
    $script:Rebuilding = $true
    $script:lbBrands.Items.Clear()
    foreach ($li in $script:AllItems) {
        $b = $li.Tag
        if (-not $q -or $b.Name.IndexOf($q, [StringComparison]::OrdinalIgnoreCase) -ge 0 -or $b.Category.IndexOf($q, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
            [void]$script:lbBrands.Items.Add($li)
        }
    }
    $script:Rebuilding = $false
    if ($script:lbBrands.Items.Count -gt 0) {
        $i = 0
        if ($prev) { for ($k = 0; $k -lt $script:lbBrands.Items.Count; $k++) { if ($script:lbBrands.Items[$k].Tag.Name -eq $prev.Name) { $i = $k; break } } }
        $script:lbBrands.SelectedIndex = $i
    } else {
        $script:txtBrand.Text = 'No match'; $script:catPill.Visibility = 'Collapsed'
    }
}

function Set-Busy([bool]$On) {
    $script:rootGrid.IsHitTestVisible = -not $On
    [System.Windows.Input.Mouse]::OverrideCursor = $(if ($On) { [System.Windows.Input.Cursors]::Wait } else { $null })
    Update-UI
}

function Invoke-Step([string]$Label, [scriptblock]$Action) {
    try { & $Action }
    catch { $script:Fails++; Write-Log "$Label failed: $($_.Exception.Message)" }
}

function Invoke-Apply {
    $brand = Get-SelectedBrand
    if (-not $brand) { return }
    $on = @($script:swWall, $script:swLock, $script:swAccent, $script:swDark, $script:swIcons, $script:swDesk, $script:swStart) | Where-Object { $_.IsChecked }
    if (-not $on) { [void](Show-Dialog 'Nothing selected' 'Turn on at least one option to apply.'); return }
    $script:Fails = 0
    Set-Busy $true
    try {
        $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $wv = $script:WallIdx; $lv = $script:LockIdx
        $dark = [bool]$script:swDark.IsChecked
        Write-Log 'Applying...'
        $icons = $null
        if ($script:swIcons.IsChecked -or $script:swDesk.IsChecked -or $script:swStart.IsChecked) {
            Invoke-Step 'Icon set' { $script:icons = Build-BrandIcons $brand }
            $icons = $script:icons
        }
        if ($script:swWall.IsChecked)   { Write-Log 'Wallpaper...';  Invoke-Step 'Wallpaper'  { Set-BrandWallpaper $brand $b.Width $b.Height $wv } }
        if ($script:swLock.IsChecked)   { Write-Log 'Lock screen...'; Invoke-Step 'Lock screen' { Set-BrandLockScreen $brand $b.Width $b.Height $lv } }
        if ($script:swAccent.IsChecked) { Write-Log 'Colours...';    Invoke-Step 'Accent colour' { Set-BrandAccent $brand $dark } }
        elseif ($dark)                  { Invoke-Step 'Dark mode' { Set-DarkModeOnly } }
        if ($icons) {
            Write-Log 'Icons...'
            if ($script:swIcons.IsChecked) { Invoke-Step 'System icons'  { Set-ShellIcons $icons } }
            if ($script:swDesk.IsChecked)  { Invoke-Step 'Desktop icons' { Set-DesktopIcons $icons } }
            if ($script:swStart.IsChecked) { Invoke-Step 'Start menu icons' { Set-StartFolderIcons $icons } }
        }
        Write-State
        Invoke-Step 'Refresh' { Update-ShellIcons }
        if ($script:Fails -gt 0) { Write-Log "Finished with $($script:Fails) issue(s). See ••• > Activity log." }
        else { Write-Log 'Applied. Sign out and back in to see everything.' }
    } finally { Set-Busy $false }
}

function Invoke-Restore {
    if (-not (Show-Dialog 'Restore defaults' 'This puts back your original wallpaper, lock screen, colours and icons.' 'Restore' 'Cancel')) { return }
    Set-Busy $true
    try { Restore-All } finally { Set-Busy $false }
}

function Step-Wall([int]$Delta) { $script:WallIdx = ($script:WallIdx + $Delta + $script:VariantCount) % $script:VariantCount; Update-WallPreview }
function Step-Lock([int]$Delta) { $script:LockIdx = ($script:LockIdx + $Delta + $script:VariantCount) % $script:VariantCount; Update-LockPreview }
function Set-RandomWall { $script:WallIdx = Get-Random -Maximum $script:VariantCount; Update-WallPreview }
function Set-RandomLock { $script:LockIdx = Get-Random -Maximum $script:VariantCount; Update-LockPreview }
function Set-RandomTheme {
    $n = $script:lbBrands.Items.Count
    if ($n -gt 0) {
        $script:lbBrands.SelectedIndex = Get-Random -Maximum $n
        $script:WallIdx = Get-Random -Maximum $script:VariantCount
        $script:LockIdx = Get-Random -Maximum $script:VariantCount
        Update-WallPreview; Update-LockPreview
    }
}

# ------------------------------------------------------------------ main window
$script:MainXaml = @'
<Window {{HEAD}} Title="BrandyTheme" Width="1200" Height="790" MinWidth="1060" MinHeight="730"
        WindowStartupLocation="CenterScreen" Background="{DynamicResource Bg}" Foreground="{DynamicResource Text}">
  <Window.Resources>{{RES}}</Window.Resources>
  <Grid x:Name="Root">
    <Grid.ColumnDefinitions><ColumnDefinition Width="292"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>

    <!-- sidebar -->
    <Border Background="{StaticResource Side}" BorderBrush="{StaticResource Stroke}" BorderThickness="0,0,1,0">
      <Grid Margin="18,22,14,18">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Orientation="Horizontal" Margin="2,0,0,20">
          <Image x:Name="LogoImg" Width="40" Height="40"/>
          <StackPanel Margin="12,0,0,0" VerticalAlignment="Center">
            <TextBlock Text="BrandyTheme" FontSize="18" FontWeight="SemiBold"/>
            <TextBlock x:Name="VerText" FontSize="12" Foreground="{StaticResource Sub}"/>
          </StackPanel>
        </StackPanel>
        <TextBox x:Name="SearchBox" Grid.Row="1" Style="{StaticResource Search}" Margin="0,0,4,12"/>
        <ListBox x:Name="BrandList" Grid.Row="2" ItemContainerStyle="{StaticResource BrandItem}" Margin="0,0,0,0"/>
        <Button x:Name="RandomBtn" Grid.Row="3" Style="{StaticResource Soft}" Height="44" Margin="0,12,4,0" Content="Random theme"/>
      </Grid>
    </Border>

    <!-- main -->
    <Grid Grid.Column="1">
      <Rectangle VerticalAlignment="Top" Height="280" IsHitTestVisible="False" Opacity="0.20">
        <Rectangle.Fill><LinearGradientBrush StartPoint="0,0" EndPoint="0,1">
          <GradientStop Color="{DynamicResource AccentColor}" Offset="0"/><GradientStop Color="#00000000" Offset="1"/>
        </LinearGradientBrush></Rectangle.Fill>
      </Rectangle>
      <Grid Margin="34,28,34,26">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- header -->
        <Grid Margin="0,0,0,22">
          <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
            <TextBlock x:Name="BrandTitle" FontSize="34" FontWeight="SemiBold"/>
            <Border x:Name="CatPill" Background="{StaticResource Card2}" CornerRadius="12" Padding="12,4" Margin="16,8,0,0" VerticalAlignment="Center">
              <TextBlock x:Name="BrandCat" FontSize="12" Foreground="#B9C0CF"/>
            </Border>
          </StackPanel>
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center">
            <Button x:Name="UpdBtn" Style="{StaticResource Ghost}" Content="Updates" Height="38"/>
            <Button x:Name="AboutBtn" Style="{StaticResource Ghost}" Content="About" Height="38" Margin="2,0,0,0"/>
            <Button x:Name="MoreBtn" Style="{StaticResource IconBtn}" Content="&#xE712;" Margin="2,0,0,0"/>
          </StackPanel>
          <Popup x:Name="MorePopup" PlacementTarget="{Binding ElementName=MoreBtn}" Placement="Bottom" HorizontalOffset="-230" VerticalOffset="6"
                 StaysOpen="False" AllowsTransparency="True" PopupAnimation="Fade">
            <Border Background="{StaticResource Card2}" BorderBrush="{StaticResource Stroke}" BorderThickness="1" CornerRadius="14" Padding="8" Width="252" Margin="8">
              <Border.Effect><DropShadowEffect BlurRadius="24" ShadowDepth="4" Opacity="0.45"/></Border.Effect>
              <StackPanel>
                <ToggleButton x:Name="SwAuto" Style="{StaticResource Switch}" Content="Update on start" Margin="10,10,10,10"/>
                <Border Height="1" Background="{StaticResource Stroke}" Margin="6,0"/>
                <Button x:Name="OpenLog" Style="{StaticResource Ghost}" Content="Activity log" HorizontalContentAlignment="Left" Height="38" Margin="0,4,0,0"/>
                <Button x:Name="OpenData" Style="{StaticResource Ghost}" Content="Open data folder" HorizontalContentAlignment="Left" Height="38"/>
                <Button x:Name="OpenWeb" Style="{StaticResource Ghost}" Content="GitHub" HorizontalContentAlignment="Left" Height="38"/>
              </StackPanel>
            </Border>
          </Popup>
        </Grid>

        <!-- previews -->
        <Grid Grid.Row="1" MinHeight="230">
          <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="16"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>

          <Border Background="{StaticResource Card}" BorderBrush="{StaticResource Stroke}" BorderThickness="1" CornerRadius="20" Padding="16">
            <Grid>
              <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
              <Grid Margin="2,0,0,12" Height="32">
                <TextBlock Text="Wallpaper" FontSize="16" FontWeight="SemiBold" VerticalAlignment="Center"/>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                  <TextBlock x:Name="WallCount" Foreground="{StaticResource Sub}" FontSize="13" VerticalAlignment="Center" Margin="0,0,6,0"/>
                  <Button x:Name="WallShuffle" Style="{StaticResource IconBtn}" Content="&#xE8B1;" Width="32" Height="32"/>
                </StackPanel>
              </Grid>
              <Grid Grid.Row="1">
                <Rectangle RadiusX="14" RadiusY="14"><Rectangle.Fill><ImageBrush x:Name="WallBrush" Stretch="UniformToFill"/></Rectangle.Fill></Rectangle>
                <Button x:Name="WallPrev" Style="{StaticResource Round}" Content="&#xE76B;" HorizontalAlignment="Left" Margin="12,0,0,0"/>
                <Button x:Name="WallNext" Style="{StaticResource Round}" Content="&#xE76C;" HorizontalAlignment="Right" Margin="0,0,12,0"/>
              </Grid>
            </Grid>
          </Border>

          <Border Grid.Column="2" Background="{StaticResource Card}" BorderBrush="{StaticResource Stroke}" BorderThickness="1" CornerRadius="20" Padding="16">
            <Grid>
              <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
              <Grid Margin="2,0,0,12" Height="32">
                <TextBlock Text="Lock screen" FontSize="16" FontWeight="SemiBold" VerticalAlignment="Center"/>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                  <TextBlock x:Name="LockCount" Foreground="{StaticResource Sub}" FontSize="13" VerticalAlignment="Center" Margin="0,0,6,0"/>
                  <Button x:Name="LockShuffle" Style="{StaticResource IconBtn}" Content="&#xE8B1;" Width="32" Height="32"/>
                </StackPanel>
              </Grid>
              <Grid Grid.Row="1">
                <Rectangle RadiusX="14" RadiusY="14"><Rectangle.Fill><ImageBrush x:Name="LockBrush" Stretch="UniformToFill"/></Rectangle.Fill></Rectangle>
                <Button x:Name="LockPrev" Style="{StaticResource Round}" Content="&#xE76B;" HorizontalAlignment="Left" Margin="12,0,0,0"/>
                <Button x:Name="LockNext" Style="{StaticResource Round}" Content="&#xE76C;" HorizontalAlignment="Right" Margin="0,0,12,0"/>
              </Grid>
            </Grid>
          </Border>
        </Grid>

        <!-- icons -->
        <Border Grid.Row="2" Background="{StaticResource Card}" BorderBrush="{StaticResource Stroke}" BorderThickness="1" CornerRadius="20" Padding="20,14" Margin="0,16,0,0">
          <DockPanel>
            <TextBlock Text="Icons" FontSize="16" FontWeight="SemiBold" VerticalAlignment="Center" Width="76" DockPanel.Dock="Left"/>
            <WrapPanel x:Name="IconPanel" VerticalAlignment="Center"/>
          </DockPanel>
        </Border>

        <!-- options -->
        <Border Grid.Row="3" Background="{StaticResource Card}" BorderBrush="{StaticResource Stroke}" BorderThickness="1" CornerRadius="20" Padding="22,14" Margin="0,16,0,0">
          <UniformGrid Columns="4">
            <ToggleButton x:Name="SwWall"   Style="{StaticResource Switch}" Content="Wallpaper"     IsChecked="True" Margin="0,8"/>
            <ToggleButton x:Name="SwLock"   Style="{StaticResource Switch}" Content="Lock screen"   IsChecked="True" Margin="0,8"/>
            <ToggleButton x:Name="SwAccent" Style="{StaticResource Switch}" Content="Accent colour" IsChecked="True" Margin="0,8"/>
            <ToggleButton x:Name="SwDark"   Style="{StaticResource Switch}" Content="Dark mode"     Margin="0,8"/>
            <ToggleButton x:Name="SwIcons"  Style="{StaticResource Switch}" Content="System icons"  IsChecked="True" Margin="0,8"/>
            <ToggleButton x:Name="SwDesk"   Style="{StaticResource Switch}" Content="Desktop icons" IsChecked="True" Margin="0,8"/>
            <ToggleButton x:Name="SwStart"  Style="{StaticResource Switch}" Content="Start menu icons" IsChecked="True" Margin="0,8"/>
          </UniformGrid>
        </Border>

        <!-- footer -->
        <Grid Grid.Row="4" Margin="0,20,0,0">
          <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
          <Button x:Name="ApplyBtn" Style="{StaticResource Solid}" Content="Apply theme" Width="220" Height="50" FontSize="16"/>
          <Button x:Name="RestoreBtn" Grid.Column="1" Style="{StaticResource Soft}" Content="Restore defaults" Width="170" Height="50" Margin="12,0,0,0"/>
          <TextBlock x:Name="StatusText" Grid.Column="2" Margin="22,0,0,0" VerticalAlignment="Center" Foreground="{StaticResource Sub}" FontSize="13" TextTrimming="CharacterEllipsis"/>
        </Grid>
      </Grid>
    </Grid>
  </Grid>
</Window>
'@

try {
    Set-Content -LiteralPath (Join-Path $script:DataDir 'app.log') -Value ("BrandyTheme $($script:AppVersion) starting {0:u}" -f (Get-Date)) -Encoding UTF8
    $script:win = ConvertFrom-Xaml $script:MainXaml
    Write-Trace 'layout parsed'
    $win = $script:win
    Set-WpfChrome $win
    $script:Rebuilding = $false; $script:CurrentBrand = ''; $script:WallIdx = 0; $script:LockIdx = 0; $script:Fails = 0

    # window / taskbar icon + logo
    $logoBmp = New-AppIconBitmap 256
    $logoSrc = ConvertTo-BitmapSource $logoBmp; $logoBmp.Dispose()
    $win.Icon = $logoSrc
    $win.FindName('LogoImg').Source = $logoSrc
    $win.FindName('VerText').Text = "Version $($script:AppVersion)"

    # controls
    $script:rootGrid   = $win.FindName('Root')
    $script:tbSearch   = $win.FindName('SearchBox')
    $script:lbBrands   = $win.FindName('BrandList')
    $script:txtBrand   = $win.FindName('BrandTitle')
    $script:txtCat     = $win.FindName('BrandCat')
    $script:catPill    = $win.FindName('CatPill')
    $script:txtStatus  = $win.FindName('StatusText')
    $script:brushWall  = $win.FindName('WallBrush');  $script:txtWallCount = $win.FindName('WallCount')
    $script:brushLock  = $win.FindName('LockBrush');  $script:txtLockCount = $win.FindName('LockCount')
    $script:swWall = $win.FindName('SwWall'); $script:swLock = $win.FindName('SwLock'); $script:swAccent = $win.FindName('SwAccent')
    $script:swDark = $win.FindName('SwDark'); $script:swIcons = $win.FindName('SwIcons'); $script:swDesk = $win.FindName('SwDesk'); $script:swStart = $win.FindName('SwStart')
    $popup = $win.FindName('MorePopup'); $script:swAuto = $win.FindName('SwAuto')
    $script:swAuto.IsChecked = [bool]$script:Settings.AutoUpdate

    # icon strip
    $script:iconImages = @()
    foreach ($k in 'Folder', 'FolderOpen', 'File', 'App', 'Drive', 'Disc', 'Pc', 'Recycle', 'Network', 'User', 'Control') {
        $img = New-Object System.Windows.Controls.Image
        $img.Width = 44; $img.Height = 44; $img.Margin = New-Object System.Windows.Thickness(0, 2, 16, 2); $img.Tag = $k
        [System.Windows.Media.RenderOptions]::SetBitmapScalingMode($img, 'HighQuality')
        [void]$win.FindName('IconPanel').Children.Add($img)
        $script:iconImages += $img
    }

    # brand list (items are built once)
    $script:AllItems = @(foreach ($b in $script:Brands) { New-BrandListItem $b })

    # events - every handler is wrapped so a problem is reported instead of closing the app
    $script:popup = $popup
    $script:lbBrands.Add_SelectionChanged({ if (-not $script:Rebuilding) { Invoke-Safe { Update-Brand } 'select brand' } })
    $script:tbSearch.Add_TextChanged({ Invoke-Safe { Update-BrandList } 'search' })
    $win.FindName('RandomBtn').Add_Click({ Invoke-Safe { Set-RandomTheme } 'random theme' })
    $win.FindName('WallPrev').Add_Click({ Invoke-Safe { Step-Wall -1 } 'wallpaper' })
    $win.FindName('WallNext').Add_Click({ Invoke-Safe { Step-Wall 1 } 'wallpaper' })
    $win.FindName('WallShuffle').Add_Click({ Invoke-Safe { Set-RandomWall } 'wallpaper' })
    $win.FindName('LockPrev').Add_Click({ Invoke-Safe { Step-Lock -1 } 'lock screen' })
    $win.FindName('LockNext').Add_Click({ Invoke-Safe { Step-Lock 1 } 'lock screen' })
    $win.FindName('LockShuffle').Add_Click({ Invoke-Safe { Set-RandomLock } 'lock screen' })
    $win.FindName('ApplyBtn').Add_Click({ Invoke-Safe { Invoke-Apply } 'apply' })
    $win.FindName('RestoreBtn').Add_Click({ Invoke-Safe { Invoke-Restore } 'restore' })
    $win.FindName('AboutBtn').Add_Click({ Invoke-Safe { Show-About } 'about' })
    $win.FindName('UpdBtn').Add_Click({ Invoke-Safe { Invoke-UpdateCheck $false } 'update check' })
    $win.FindName('MoreBtn').Add_Click({ $script:popup.IsOpen = $true })
    $script:swAuto.Add_Click({ Invoke-Safe { $script:Settings.AutoUpdate = [bool]$script:swAuto.IsChecked; Write-Settings } 'settings' })
    $win.FindName('OpenLog').Add_Click({ $script:popup.IsOpen = $false; Invoke-Safe { Show-LogViewer } 'log' })
    $win.FindName('OpenData').Add_Click({ $script:popup.IsOpen = $false; Invoke-Safe { Start-Process explorer.exe $script:DataDir } 'open folder' })
    $win.FindName('OpenWeb').Add_Click({ $script:popup.IsOpen = $false; Invoke-Safe { Start-Process $script:GitHubUrl } 'open website' })

    # anything that still escapes a handler (layout/render errors) is reported here instead of crashing the process
    $win.Dispatcher.Add_UnhandledException({ param($s, $e) $e.Handled = $true; Write-AppError $e.Exception 'window' })

    $win.Add_Loaded({ Write-Trace 'window loaded'; Invoke-Safe { Update-BrandList } 'load brands' })
    $win.Add_ContentRendered({
        Invoke-Safe {
            if (-not $script:FirstRender) {
                $script:FirstRender = $true
                Write-Trace 'window shown'
                if ($script:Settings.AutoUpdate -and -not $NoUpdateCheck) { Invoke-UpdateCheck $true }
            }
        } 'startup'
    })
    Write-Trace 'showing window'

    [void]$win.ShowDialog()
} catch {
    Write-AppError $_ 'startup'
    exit 1
}
