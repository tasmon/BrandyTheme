#Requires -Version 5.1
<#
.SYNOPSIS
    Installs or uninstalls BrandyTheme as a standard Windows application.

.DESCRIPTION
    Install  : copies the app to C:\Program Files\BrandyTheme, creates a Start menu shortcut and
               registers the app in Settings > Apps > Installed apps (Add/Remove Programs).
    Uninstall: optionally reverts all theme changes, then removes everything.

.EXAMPLE
    .\Install-BrandyTheme.ps1
.EXAMPLE
    .\Install-BrandyTheme.ps1 -Uninstall
.EXAMPLE
    .\Install-BrandyTheme.ps1 -Silent        # unattended install
#>
[CmdletBinding()]
param(
    [switch]$Uninstall,
    [switch]$Silent,
    [string]$InstallDir = (Join-Path $env:ProgramFiles 'BrandyTheme')
)

$ErrorActionPreference = 'Stop'
$AppName = 'BrandyTheme'

# ---- elevate
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $a = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -InstallDir `"$InstallDir`""
    if ($Uninstall) { $a += ' -Uninstall' }
    if ($Silent)    { $a += ' -Silent' }
    Start-Process -FilePath powershell.exe -ArgumentList $a -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
function Show-Msg([string]$Text, [string]$Icon = 'Information') {
    if ($Silent) { Write-Host $Text } else { [void][System.Windows.Forms.MessageBox]::Show($Text, "$AppName setup", 'OK', $Icon) }
}

$UninstallKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$AppName"
$StartLink    = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\$AppName.lnk"
$DataDir      = Join-Path $env:ProgramData $AppName

try {
    if (-not $Uninstall) {
        # ------------------------------------------------------------ INSTALL
        $srcScript = Join-Path $PSScriptRoot 'BrandyTheme.ps1'
        if (-not (Test-Path -LiteralPath $srcScript)) { throw 'BrandyTheme.ps1 must be in the same folder as this installer.' }
        $m = Select-String -Path $srcScript -Pattern "AppVersion\s*=\s*'([^']+)'" | Select-Object -First 1
        $version = $m.Matches[0].Groups[1].Value

        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        if ((Resolve-Path $PSScriptRoot).Path -ne (Resolve-Path $InstallDir).Path) {
            foreach ($f in 'BrandyTheme.ps1', 'Install-BrandyTheme.ps1', 'README.md', 'LICENSE') {
                $p = Join-Path $PSScriptRoot $f
                if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination $InstallDir -Force }
            }
            $logos = Join-Path $PSScriptRoot 'logos'
            if (Test-Path -LiteralPath $logos) { Copy-Item -LiteralPath $logos -Destination $InstallDir -Recurse -Force }
        }
        Get-ChildItem -LiteralPath $InstallDir -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

        $mainScript = Join-Path $InstallDir 'BrandyTheme.ps1'
        $iconFile   = Join-Path $DataDir 'BrandyTheme.ico'
        Start-Process -FilePath powershell.exe -Wait -WindowStyle Hidden `
            -ArgumentList "-NoProfile -STA -ExecutionPolicy Bypass -File `"$mainScript`" -ExportAppIcon"

        # Start menu shortcut
        $ws = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut($StartLink)
        $lnk.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $lnk.Arguments = "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$mainScript`""
        $lnk.WorkingDirectory = $InstallDir
        $lnk.Description = 'Apply branded themes, wallpapers, lock screens and icons'
        if (Test-Path -LiteralPath $iconFile) { $lnk.IconLocation = $iconFile }
        $lnk.Save()

        # Add/Remove Programs entry
        New-Item -Path $UninstallKey -Force | Out-Null
        $props = @{
            DisplayName     = $AppName
            DisplayVersion  = $version
            Publisher       = 'Tasmon Islam'
            InstallLocation = $InstallDir
            DisplayIcon     = $iconFile
            URLInfoAbout    = 'https://github.com/tasmon/BrandyTheme'
            HelpLink        = 'mailto:tasmon@outlook.com'
            UninstallString = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$(Join-Path $InstallDir 'Install-BrandyTheme.ps1')`" -Uninstall"
        }
        foreach ($k in $props.Keys) { New-ItemProperty -Path $UninstallKey -Name $k -Value $props[$k] -PropertyType String -Force | Out-Null }
        New-ItemProperty -Path $UninstallKey -Name NoModify -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $UninstallKey -Name NoRepair -Value 1 -PropertyType DWord -Force | Out-Null
        $kb = [int]((Get-ChildItem -LiteralPath $InstallDir -Recurse -File | Measure-Object Length -Sum).Sum / 1KB)
        New-ItemProperty -Path $UninstallKey -Name EstimatedSize -Value $kb -PropertyType DWord -Force | Out-Null

        Show-Msg "$AppName $version was installed.`r`n`r`nFind it in the Start menu." 'Information'
    }
    else {
        # ------------------------------------------------------------ UNINSTALL
        $restore = $true
        if (-not $Silent) {
            $ans = [System.Windows.Forms.MessageBox]::Show(
                "Restore your original wallpaper, lock screen, colours and icons before uninstalling?`r`n`r`n(Choose No to keep the current look; the icon files will then be left in place so nothing breaks.)",
                "$AppName setup", 'YesNoCancel', 'Question')
            if ($ans -eq 'Cancel') { exit }
            $restore = ($ans -eq 'Yes')
        }
        $mainScript = Join-Path $InstallDir 'BrandyTheme.ps1'
        if ($restore -and (Test-Path -LiteralPath $mainScript)) {
            Start-Process -FilePath powershell.exe -Wait -WindowStyle Hidden `
                -ArgumentList "-NoProfile -STA -ExecutionPolicy Bypass -File `"$mainScript`" -RestoreDefaults"
        }
        if (Test-Path -LiteralPath $StartLink)   { Remove-Item -LiteralPath $StartLink -Force }
        if (Test-Path -LiteralPath $UninstallKey) { Remove-Item -LiteralPath $UninstallKey -Recurse -Force }
        if ($restore -and (Test-Path -LiteralPath $DataDir)) { Remove-Item -LiteralPath $DataDir -Recurse -Force -ErrorAction SilentlyContinue }

        # delete the install folder after this script has exited
        Start-Process -FilePath cmd.exe -WindowStyle Hidden `
            -ArgumentList "/c ping -n 3 127.0.0.1 >nul & rmdir /s /q `"$InstallDir`""
        Show-Msg "$AppName was uninstalled." 'Information'
    }
}
catch {
    Show-Msg "Setup failed:`r`n$($_.Exception.Message)" 'Error'
    exit 1
}
