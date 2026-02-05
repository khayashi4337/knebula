@echo off
REM =====================================
REM Nebula Service Uninstallation
REM =====================================
REM Run as Administrator

echo Uninstalling Nebula Service...

set NEBULA_DIR=%~dp0
set NEBULA_DIR=%NEBULA_DIR:~0,-1%

REM Check if service exists
sc query NebulaMember >nul 2>&1
if %errorlevel% neq 0 (
    echo Service NebulaMember does not exist.
    pause
    exit /b 0
)

REM Stop service first
"%NEBULA_DIR%\nssm.exe" stop NebulaMember 2>nul

REM Remove service
"%NEBULA_DIR%\nssm.exe" remove NebulaMember confirm

echo.
echo Service removed.
echo.
pause
