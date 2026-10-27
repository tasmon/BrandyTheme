@echo off
setlocal EnableExtensions
title BrandyTheme setup
cd /d "%~dp0"

rem ======================================================================
rem  Install BrandyTheme.cmd  -  double-click, then choose:
rem     1 = Install / Update      2 = Uninstall      3 = Exit
rem  Optional switches (skip the menu):  /install  /update  /uninstall  /silent
rem  Created by Tasmon Islam - tasmon@outlook.com
rem ======================================================================

set "PS1=%~dp0Install-BrandyTheme.ps1"
set "APPDIR=%ProgramFiles%\BrandyTheme"
set "REGKEY=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\BrandyTheme"

if not exist "%PS1%" goto missing

rem ---- administrator rights are required: re-open this window elevated
net session >nul 2>&1
if %errorlevel% equ 0 goto elevated
echo Asking for administrator permission...
if "%~1"=="" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs"
)
exit /b

:elevated
rem ---- files from a downloaded zip are "blocked"; unblock them once
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%~dp0' -Recurse -File | Unblock-File -ErrorAction SilentlyContinue"

set "ACTION="
set "SILENT="
:parse
if "%~1"=="" goto parsed
if /I "%~1"=="/install"   set "ACTION=install"
if /I "%~1"=="/update"    set "ACTION=install"
if /I "%~1"=="/uninstall" set "ACTION=uninstall"
if /I "%~1"=="/silent"    set "SILENT=1"
shift
goto parse
:parsed

:detect
set "INSTVER="
set "NEWVER=unknown"
for /f "tokens=2,*" %%a in ('reg query "%REGKEY%" /v DisplayVersion 2^>nul') do if /I "%%a"=="REG_SZ" set "INSTVER=%%b"
for /f "tokens=2 delims='" %%v in ('findstr /b /l /c:"$script:AppVersion" "%~dp0BrandyTheme.ps1"') do set "NEWVER=%%v"

if defined ACTION goto %ACTION%

:menu
cls
echo.
echo    ==========================================
echo      BrandyTheme setup
echo    ==========================================
echo.
if defined INSTVER (echo      Installed version : %INSTVER%) else (echo      Installed version : not installed)
echo      This package      : %NEWVER%
echo.
if defined INSTVER (echo      [1] Update to %NEWVER%) else (echo      [1] Install)
echo      [2] Uninstall
echo      [3] Exit
echo.
choice /c 123 /n /m "     Choose 1, 2 or 3: "
if errorlevel 3 goto done
if errorlevel 2 goto uninstall
goto install

:install
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Silent
set "RC=%errorlevel%"
if not "%RC%"=="0" goto failed
echo.
echo   Done.
if defined SILENT goto done
echo.
choice /c YN /n /m "  Open BrandyTheme now? [Y/N] "
if errorlevel 2 goto aftermenu
if exist "%APPDIR%\BrandyTheme.exe" (
    start "" "%APPDIR%\BrandyTheme.exe"
) else (
    start "" powershell -NoProfile -STA -ExecutionPolicy Bypass -WindowStyle Hidden -File "%APPDIR%\BrandyTheme.ps1"
)
goto done

:uninstall
if not defined INSTVER (
    echo.
    echo   BrandyTheme is not installed.
    if not defined SILENT pause
    if defined ACTION goto done
    goto menu
)
set "KEEP="
if not defined SILENT (
    echo.
    choice /c YN /n /m "  Restore your original wallpaper, colours and icons first? [Y/N] "
    if errorlevel 2 set "KEEP=-KeepTheme"
)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%" -Uninstall -Silent %KEEP%
set "RC=%errorlevel%"
if not "%RC%"=="0" goto failed
echo.
echo   BrandyTheme was uninstalled.
goto aftermenu

:failed
echo.
echo   Setup stopped with an error ^(code %RC%^). Nothing else was changed.
pause
goto aftermenu

:missing
echo Install-BrandyTheme.ps1 was not found next to this file.
echo Extract the whole BrandyTheme zip first, then run this file again.
pause
exit /b 1

:aftermenu
if defined ACTION goto done
echo.
pause
goto detect

:done
endlocal
exit /b 0
