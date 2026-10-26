#Requires -Version 5.1
<#
.SYNOPSIS
    Installs or uninstalls BrandyTheme as a standard Windows application.

.DESCRIPTION
    Install  : copies the app to C:\Program Files\BrandyTheme, builds BrandyTheme.exe (a tiny native
               launcher that hosts the script, so the taskbar shows the BrandyTheme icon instead of
               PowerShell's), adds a Start menu shortcut and registers the app in
               Settings > Apps > Installed apps.
    Uninstall: optionally reverts all theme changes first, then removes everything.

    Normally started through "Install BrandyTheme.cmd" (double-click).

.EXAMPLE
    .\Install-BrandyTheme.ps1
.EXAMPLE
    .\Install-BrandyTheme.ps1 -Uninstall
.EXAMPLE
    .\Install-BrandyTheme.ps1 -Silent
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

# ---------------------------------------------------------------- native launcher (BrandyTheme.exe)
# The exe is elevated through its manifest, runs BrandyTheme.ps1 inside its OWN process (in-process
# PowerShell runspace) and carries the BrandyTheme icon - so there is no powershell.exe window or
# taskbar icon at all.
$LauncherSource = @'
using System;
using System.IO;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Threading;
using System.Windows.Forms;

public static class BrandyThemeHost
{
    [STAThread]
    public static int Main(string[] args)
    {
        string dir = AppDomain.CurrentDomain.BaseDirectory;
        string script = Path.Combine(dir, "BrandyTheme.ps1");
        if (!File.Exists(script))
        {
            MessageBox.Show("BrandyTheme.ps1 was not found next to BrandyTheme.exe.", "BrandyTheme",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 2;
        }
        try
        {
            InitialSessionState iss = InitialSessionState.CreateDefault();
            iss.ApartmentState = ApartmentState.STA;
            iss.ThreadOptions = PSThreadOptions.UseCurrentThread;
            iss.ExecutionPolicy = Microsoft.PowerShell.ExecutionPolicy.Bypass;
            using (Runspace rs = RunspaceFactory.CreateRunspace(iss))
            {
                rs.Open();
                using (PowerShell ps = PowerShell.Create())
                {
                    ps.Runspace = rs;
                    ps.AddCommand(script);
                    foreach (string a in args)
                    {
                        if (a.StartsWith("-")) ps.AddParameter(a.TrimStart('-'));
                    }
                    ps.Invoke();
                }
            }
            return 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show("BrandyTheme could not start:\r\n\r\n" + ex.Message, "BrandyTheme",
                MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
'@

$LauncherManifest = @'
<?xml version="1.0" encoding="utf-8"?>
<assembly manifestVersion="1.0" xmlns="urn:schemas-microsoft-com:asm.v1">
  <assemblyIdentity version="1.0.0.0" name="Tasmon.BrandyTheme" type="win32"/>
  <description>BrandyTheme</description>
  <dependency>
    <dependentAssembly>
      <assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls" version="6.0.0.0" processorArchitecture="*" publicKeyToken="6595b64144ccf1df" language="*"/>
    </dependentAssembly>
  </dependency>
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
    <security><requestedPrivileges><requestedExecutionLevel level="requireAdministrator" uiAccess="false"/></requestedPrivileges></security>
  </trustInfo>
  <compatibility xmlns="urn:schemas-microsoft-com:compatibility.v1">
    <application>
      <supportedOS Id="{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"/>
      <supportedOS Id="{e2011457-1546-43c5-a5fe-008deee3d3f0}"/>
      <supportedOS Id="{35138b9a-5d96-4fbd-8e2d-a2440225f93a}"/>
    </application>
  </compatibility>
  <application xmlns="urn:schemas-microsoft-com:asm.v3">
    <windowsSettings><dpiAware xmlns="http://schemas.microsoft.com/SMI/2005/WindowsSettings">true</dpiAware></windowsSettings>
  </application>
</assembly>
'@

function New-Launcher([string]$Dir, [string]$IconFile) {
    $exe = Join-Path $Dir 'BrandyTheme.exe'
    if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe -Force }
    $manifest = Join-Path $env:TEMP 'BrandyTheme.manifest'
    Set-Content -LiteralPath $manifest -Value $LauncherManifest -Encoding UTF8
    $refs = @('System.Windows.Forms', [psobject].Assembly.Location)

    $attempts = @()
    if (Test-Path -LiteralPath $IconFile) { $attempts += "/win32manifest:`"$manifest`" /win32icon:`"$IconFile`"" }
    $attempts += "/win32manifest:`"$manifest`""          # retry without the embedded icon if the first build fails

    foreach ($opts in $attempts) {
        try {
            Add-Type -TypeDefinition $LauncherSource -Language CSharp -ReferencedAssemblies $refs `
                -OutputAssembly $exe -OutputType WindowsApplication -CompilerOptions $opts
            if (Test-Path -LiteralPath $exe) { return $exe }
        } catch {
            if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe -Force -ErrorAction SilentlyContinue }
            Write-Verbose $_.Exception.Message
        }
    }
    $null
}

try {
    if (-not $Uninstall) {
        # ------------------------------------------------------------ INSTALL
        $srcScript = Join-Path $PSScriptRoot 'BrandyTheme.ps1'
        if (-not (Test-Path -LiteralPath $srcScript)) { throw 'BrandyTheme.ps1 must be in the same folder as this installer.' }
        $m = Select-String -Path $srcScript -Pattern "AppVersion\s*=\s*'([^']+)'" | Select-Object -First 1
        $version = $m.Matches[0].Groups[1].Value

        Get-Process -Name BrandyTheme -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        if ((Resolve-Path $PSScriptRoot).Path -ne (Resolve-Path $InstallDir).Path) {
            foreach ($f in 'BrandyTheme.ps1', 'Install-BrandyTheme.ps1', 'Install BrandyTheme.cmd', 'README.md', 'LICENSE') {
                $p = Join-Path $PSScriptRoot $f
                if (Test-Path -LiteralPath $p) { Copy-Item -LiteralPath $p -Destination $InstallDir -Force }
            }
        }
        Get-ChildItem -LiteralPath $InstallDir -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

        $mainScript = Join-Path $InstallDir 'BrandyTheme.ps1'
        $iconFile   = Join-Path $DataDir 'BrandyTheme.ico'
        Start-Process -FilePath powershell.exe -Wait -WindowStyle Hidden `
            -ArgumentList "-NoProfile -STA -ExecutionPolicy Bypass -File `"$mainScript`" -ExportAppIcon"

        # build the launcher; fall back to a hidden powershell.exe shortcut if compiling is blocked
        $exe = New-Launcher $InstallDir $iconFile
        $ws = New-Object -ComObject WScript.Shell
        $lnk = $ws.CreateShortcut($StartLink)
        if ($exe) {
            $lnk.TargetPath = $exe
            $lnk.Arguments = ''
        } else {
            $lnk.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
            $lnk.Arguments = "-NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$mainScript`""
        }
        $lnk.WorkingDirectory = $InstallDir
        $lnk.Description = 'Branded wallpapers, lock screens and icon themes'
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

        $note = if ($exe) { '' } else { "`r`n`r`n(The native launcher could not be built on this PC, so a PowerShell shortcut was used instead.)" }
        Show-Msg "$AppName $version was installed.`r`n`r`nFind it in the Start menu.$note" 'Information'
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
        Get-Process -Name BrandyTheme -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        $mainScript = Join-Path $InstallDir 'BrandyTheme.ps1'
        if ($restore -and (Test-Path -LiteralPath $mainScript)) {
            Start-Process -FilePath powershell.exe -Wait -WindowStyle Hidden `
                -ArgumentList "-NoProfile -STA -ExecutionPolicy Bypass -File `"$mainScript`" -RestoreDefaults"
        }
        if (Test-Path -LiteralPath $StartLink)    { Remove-Item -LiteralPath $StartLink -Force }
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
