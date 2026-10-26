@echo off
setlocal EnableExtensions
title Install BrandyTheme
cd /d "%~dp0"

rem ---------------------------------------------------------------
rem  Install BrandyTheme.cmd   (double-click to install)
rem    /uninstall   remove BrandyTheme
rem    /silent      no prompts
rem  Created by Tasmon Islam - tasmon@outlook.com
rem ---------------------------------------------------------------

if not exist "%~dp0Install-BrandyTheme.ps1" (
    echo Install-BrandyTheme.ps1 was not found next to this file.
    echo Extract the whole BrandyTheme zip first, then run this file again.
    pause
    exit /b 1
)

set "PSARGS="
:parse
if "%~1"=="" goto run
if /I "%~1"=="/uninstall" set "PSARGS=%PSARGS% -Uninstall"
if /I "%~1"=="/silent"    set "PSARGS=%PSARGS% -Silent"
shift
goto parse

:run
rem -- need administrator rights; re-launch this file elevated if necessary
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator permission...
    if defined PSARGS (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs"
    ) else (
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    )
    exit /b
)

rem -- files from a downloaded zip are "blocked"; unblock them
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -LiteralPath '%~dp0' -Recurse -File | Unblock-File -ErrorAction SilentlyContinue"

echo.
echo Running BrandyTheme setup...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-BrandyTheme.ps1" %PSARGS%
if %errorlevel% neq 0 (
    echo.
    echo Setup reported an error ^(code %errorlevel%^).
    pause
    exit /b %errorlevel%
)
exit /b 0
