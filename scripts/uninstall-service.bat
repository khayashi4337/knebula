@echo off
REM =====================================
REM Nebula Service Uninstallation
REM =====================================
REM Run as Administrator

echo Uninstalling Nebula Service...

set NEBULA_DIR=%~dp0
set NEBULA_DIR=%NEBULA_DIR:~0,-1%

REM Stop service first
"%NEBULA_DIR%\nssm.exe" stop NebulaMember 2>nul

REM Remove service
"%NEBULA_DIR%\nssm.exe" remove NebulaMember confirm

echo.
echo Service removed.
echo.
pause
