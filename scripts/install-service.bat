@echo off
REM =====================================
REM Nebula Service Installation
REM =====================================
REM Run as Administrator (one-time setup)
REM After this, Nebula starts automatically on boot
REM
REM Prerequisites:
REM   - nssm.exe in the same directory
REM   - nebula.exe in the same directory
REM   - config.yml configured

echo Installing Nebula as Windows Service...

REM Get current directory
set NEBULA_DIR=%~dp0
set NEBULA_DIR=%NEBULA_DIR:~0,-1%

REM Check if nssm exists
if not exist "%NEBULA_DIR%\nssm.exe" (
    echo ERROR: nssm.exe not found!
    echo Download from https://nssm.cc/download
    pause
    exit /b 1
)

REM Check if nebula exists
if not exist "%NEBULA_DIR%\nebula.exe" (
    echo ERROR: nebula.exe not found!
    pause
    exit /b 1
)

REM Install service
"%NEBULA_DIR%\nssm.exe" install NebulaMember "%NEBULA_DIR%\nebula.exe" -config "%NEBULA_DIR%\config.yml"

REM Set service to auto-start
"%NEBULA_DIR%\nssm.exe" set NebulaMember Start SERVICE_AUTO_START

REM Set description
"%NEBULA_DIR%\nssm.exe" set NebulaMember Description "Nebula VPN Client"

REM Start the service
"%NEBULA_DIR%\nssm.exe" start NebulaMember

echo.
echo =====================================
echo Installation complete!
echo =====================================
echo.
echo Nebula will now:
echo   - Start automatically when PC boots
echo   - Run in background (no window needed)
echo.
echo To check status: sc query NebulaMember
echo To stop:         net stop NebulaMember
echo To start:        net start NebulaMember
echo.
pause
