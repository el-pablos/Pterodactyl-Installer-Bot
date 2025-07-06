@echo off
setlocal enabledelayedexpansion

title Pterodactyl Bot Windows Service Manager v2.1
color 0A

REM ============================================
REM Windows Service Wrapper for Pterodactyl Bot
REM Version: 2.1.0
REM ============================================

REM Configuration
set SERVICE_NAME=PterodactylBot
set SERVICE_DISPLAY_NAME=Pterodactyl Panel Installer Bot
set SERVICE_DESCRIPTION=Telegram bot for installing Pterodactyl panel automatically
set BOT_DIR=%~dp0
set BOT_SCRIPT=%BOT_DIR%bot.js
set LOG_DIR=%BOT_DIR%logs
set NSSM_URL=https://nssm.cc/release/nssm-2.24.zip
set NSSM_DIR=%BOT_DIR%nssm

echo.
echo ============================================
echo  Windows Service Manager for Pterodactyl Bot
echo  Version: 2.1.0
echo ============================================
echo.

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script requires administrator privileges
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

REM Create logs directory
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%"
    echo [INFO] Created logs directory: %LOG_DIR%
)

REM Show menu
:MENU
echo.
echo ============================================
echo  SERVICE MANAGEMENT MENU
echo ============================================
echo.
echo 1. Install Service
echo 2. Start Service
echo 3. Stop Service
echo 4. Restart Service
echo 5. Uninstall Service
echo 6. Check Service Status
echo 7. View Logs
echo 8. Configure Service
echo 9. Test Bot
echo 0. Exit
echo.
set /p choice="Select an option (0-9): "

if "%choice%"=="1" goto INSTALL_SERVICE
if "%choice%"=="2" goto START_SERVICE
if "%choice%"=="3" goto STOP_SERVICE
if "%choice%"=="4" goto RESTART_SERVICE
if "%choice%"=="5" goto UNINSTALL_SERVICE
if "%choice%"=="6" goto CHECK_STATUS
if "%choice%"=="7" goto VIEW_LOGS
if "%choice%"=="8" goto CONFIGURE_SERVICE
if "%choice%"=="9" goto TEST_BOT
if "%choice%"=="0" goto EXIT
goto INVALID_CHOICE

:INSTALL_SERVICE
echo.
echo [INFO] Installing Pterodactyl Bot as Windows service...

REM Check if NSSM exists
if not exist "%NSSM_DIR%\win64\nssm.exe" (
    echo [INFO] NSSM not found, downloading...
    call :DOWNLOAD_NSSM
)

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found!
    echo Please install Node.js from: https://nodejs.org/
    pause
    goto MENU
)

REM Check if bot.js exists
if not exist "%BOT_SCRIPT%" (
    echo [ERROR] bot.js not found in: %BOT_DIR%
    echo Make sure you're running this script from the bot directory
    pause
    goto MENU
)

REM Install service
echo [INFO] Installing service using NSSM...
"%NSSM_DIR%\win64\nssm.exe" install "%SERVICE_NAME%" node "%BOT_SCRIPT%"

REM Configure service
"%NSSM_DIR%\win64\nssm.exe" set "%SERVICE_NAME%" DisplayName "%SERVICE_DISPLAY_NAME%"
"%NSSM_DIR%\win64\nssm.exe" set "%SERVICE_NAME%" Description "%SERVICE_DESCRIPTION%"
"%NSSM_DIR%\win64\nssm.exe" set "%SERVICE_NAME%" AppDirectory "%BOT_DIR%"
"%NSSM_DIR%\win64\nssm.exe" set "%SERVICE_NAME%" AppStdout "%LOG_DIR%\output.log"
"%NSSM_DIR%\win64\nssm.exe" set "%SERVICE_NAME%" AppStderr "%LOG_DIR%\error.log"
"%NSSM_DIR%\win64\nssm.exe" set "%SERVICE_NAME%" AppRotateFiles 1
"%NSSM_DIR%\win64\nssm.exe" set "%SERVICE_NAME%" AppRotateOnline 1
"%NSSM_DIR%\win64\nssm.exe" set "%SERVICE_NAME%" AppRotateBytes 1048576
"%NSSM_DIR%\win64\nssm.exe" set "%SERVICE_NAME%" Start SERVICE_AUTO_START

echo [SUCCESS] Service installed successfully!
echo [INFO] Service Name: %SERVICE_NAME%
echo [INFO] Display Name: %SERVICE_DISPLAY_NAME%
echo [INFO] Output Log: %LOG_DIR%\output.log
echo [INFO] Error Log: %LOG_DIR%\error.log
echo.
echo The service will start automatically with Windows.
echo Use option 2 to start the service now.
pause
goto MENU

:START_SERVICE
echo.
echo [INFO] Starting Pterodactyl Bot service...
net start "%SERVICE_NAME%" 2>nul
if %errorlevel% equ 0 (
    echo [SUCCESS] Service started successfully!
) else (
    echo [ERROR] Failed to start service
    echo [INFO] Check service status and logs for details
)
pause
goto MENU

:STOP_SERVICE
echo.
echo [INFO] Stopping Pterodactyl Bot service...
net stop "%SERVICE_NAME%" 2>nul
if %errorlevel% equ 0 (
    echo [SUCCESS] Service stopped successfully!
) else (
    echo [ERROR] Failed to stop service or service not running
)
pause
goto MENU

:RESTART_SERVICE
echo.
echo [INFO] Restarting Pterodactyl Bot service...
net stop "%SERVICE_NAME%" 2>nul
timeout /t 3 /nobreak >nul
net start "%SERVICE_NAME%" 2>nul
if %errorlevel% equ 0 (
    echo [SUCCESS] Service restarted successfully!
) else (
    echo [ERROR] Failed to restart service
)
pause
goto MENU

:UNINSTALL_SERVICE
echo.
echo [WARNING] This will completely remove the Pterodactyl Bot service.
set /p confirm="Are you sure? (y/N): "
if /i not "%confirm%"=="y" (
    echo [INFO] Uninstall cancelled
    pause
    goto MENU
)

echo [INFO] Stopping service...
net stop "%SERVICE_NAME%" 2>nul

echo [INFO] Removing service...
if exist "%NSSM_DIR%\win64\nssm.exe" (
    "%NSSM_DIR%\win64\nssm.exe" remove "%SERVICE_NAME%" confirm
    echo [SUCCESS] Service uninstalled successfully!
) else (
    sc delete "%SERVICE_NAME%"
    echo [INFO] Service removed using sc command
)
pause
goto MENU

:CHECK_STATUS
echo.
echo [INFO] Checking service status...
echo.
sc query "%SERVICE_NAME%" 2>nul | findstr /i "state"
if %errorlevel% neq 0 (
    echo [ERROR] Service not found or not installed
) else (
    echo.
    echo [INFO] Full service information:
    sc query "%SERVICE_NAME%"
)
pause
goto MENU

:VIEW_LOGS
echo.
echo ============================================
echo  LOG VIEWER
echo ============================================
echo.
echo 1. View Output Log
echo 2. View Error Log
echo 3. View Output Log (Real-time)
echo 4. View Error Log (Real-time)
echo 5. Clear Logs
echo 6. Back to Main Menu
echo.
set /p log_choice="Select log option (1-6): "

if "%log_choice%"=="1" (
    if exist "%LOG_DIR%\output.log" (
        echo [INFO] Showing last 50 lines of output log:
        echo.
        powershell "Get-Content '%LOG_DIR%\output.log' -Tail 50"
    ) else (
        echo [WARNING] Output log not found
    )
    pause
    goto VIEW_LOGS
)

if "%log_choice%"=="2" (
    if exist "%LOG_DIR%\error.log" (
        echo [INFO] Showing last 50 lines of error log:
        echo.
        powershell "Get-Content '%LOG_DIR%\error.log' -Tail 50"
    ) else (
        echo [WARNING] Error log not found
    )
    pause
    goto VIEW_LOGS
)

if "%log_choice%"=="3" (
    if exist "%LOG_DIR%\output.log" (
        echo [INFO] Real-time output log (Press Ctrl+C to stop):
        echo.
        powershell "Get-Content '%LOG_DIR%\output.log' -Wait -Tail 10"
    ) else (
        echo [WARNING] Output log not found
    )
    goto VIEW_LOGS
)

if "%log_choice%"=="4" (
    if exist "%LOG_DIR%\error.log" (
        echo [INFO] Real-time error log (Press Ctrl+C to stop):
        echo.
        powershell "Get-Content '%LOG_DIR%\error.log' -Wait -Tail 10"
    ) else (
        echo [WARNING] Error log not found
    )
    goto VIEW_LOGS
)

if "%log_choice%"=="5" (
    echo [WARNING] This will delete all log files
    set /p clear_confirm="Are you sure? (y/N): "
    if /i "%clear_confirm%"=="y" (
        del /q "%LOG_DIR%\*.log" 2>nul
        echo [SUCCESS] Logs cleared
    ) else (
        echo [INFO] Clear cancelled
    )
    pause
    goto VIEW_LOGS
)

if "%log_choice%"=="6" goto MENU

echo [ERROR] Invalid choice
pause
goto VIEW_LOGS

:CONFIGURE_SERVICE
echo.
echo [INFO] Opening service configuration...
if exist "%NSSM_DIR%\win64\nssm.exe" (
    "%NSSM_DIR%\win64\nssm.exe" edit "%SERVICE_NAME%"
) else (
    echo [ERROR] NSSM not found. Cannot open configuration GUI.
    echo [INFO] You can manually configure the service using Windows Services console.
)
pause
goto MENU

:TEST_BOT
echo.
echo [INFO] Testing bot configuration...
echo.

REM Check Node.js
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found
    goto TEST_FAILED
)
echo [PASS] Node.js is installed

REM Check bot.js syntax
node -c "%BOT_SCRIPT%" 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Bot syntax error
    goto TEST_FAILED
)
echo [PASS] Bot syntax is valid

REM Check dependencies
if exist "%BOT_DIR%\node_modules" (
    echo [PASS] Dependencies installed
) else (
    echo [ERROR] Dependencies not installed
    echo [INFO] Run: npm install
    goto TEST_FAILED
)

REM Check configuration
if exist "%BOT_DIR%\config.js" (
    echo [PASS] Configuration file exists
) else (
    echo [ERROR] Configuration file missing
    goto TEST_FAILED
)

echo.
echo [SUCCESS] All tests passed!
echo [INFO] Bot should work correctly as a service
pause
goto MENU

:TEST_FAILED
echo.
echo [ERROR] Some tests failed
echo [INFO] Please fix the issues before installing as service
pause
goto MENU

:DOWNLOAD_NSSM
echo [INFO] Downloading NSSM (Non-Sucking Service Manager)...
if not exist "%NSSM_DIR%" mkdir "%NSSM_DIR%"

REM Download using PowerShell
powershell -Command "& {try { Invoke-WebRequest -Uri '%NSSM_URL%' -OutFile '%NSSM_DIR%\nssm.zip' -UseBasicParsing } catch { exit 1 }}"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to download NSSM
    echo [INFO] Please download manually from: %NSSM_URL%
    pause
    goto MENU
)

echo [INFO] Extracting NSSM...
powershell -Command "Expand-Archive -Path '%NSSM_DIR%\nssm.zip' -DestinationPath '%NSSM_DIR%' -Force"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to extract NSSM
    pause
    goto MENU
)

REM Move files to correct location
if exist "%NSSM_DIR%\nssm-2.24" (
    xcopy "%NSSM_DIR%\nssm-2.24\*" "%NSSM_DIR%\" /E /I /Y >nul
    rmdir /s /q "%NSSM_DIR%\nssm-2.24" 2>nul
)

del "%NSSM_DIR%\nssm.zip" 2>nul

if exist "%NSSM_DIR%\win64\nssm.exe" (
    echo [SUCCESS] NSSM downloaded and extracted
) else (
    echo [ERROR] NSSM extraction failed
    pause
    goto MENU
)
goto :eof

:INVALID_CHOICE
echo [ERROR] Invalid choice. Please select 0-9.
pause
goto MENU

:EXIT
echo.
echo [INFO] Thank you for using Pterodactyl Bot Windows Service Manager!
echo.
echo Useful Commands:
echo - Start Service: net start %SERVICE_NAME%
echo - Stop Service: net stop %SERVICE_NAME%
echo - Check Status: sc query %SERVICE_NAME%
echo.
pause
exit /b 0
