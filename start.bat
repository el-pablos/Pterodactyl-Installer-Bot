@echo off
setlocal enabledelayedexpansion

title Pterodactyl Panel Installer Bot v2.1 Enhanced
color 0A

echo.
echo ===============================================
echo   Pterodactyl Panel Installer Bot v2.1
echo   Enhanced Cross-Platform Support
echo   Developer: NdikaFath ID
echo ===============================================
echo.

REM Get current time
for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
set "YY=%dt:~2,2%" & set "YYYY=%dt:~0,4%" & set "MM=%dt:~4,2%" & set "DD=%dt:~6,2%"
set "HH=%dt:~8,2%" & set "Min=%dt:~10,2%" & set "Sec=%dt:~12,2%"
set "timestamp=%YYYY%-%MM%-%DD% %HH%:%Min%:%Sec%"

echo [%timestamp%] Starting bot initialization...

REM Check if Node.js is installed
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js tidak terdeteksi!
    echo.
    echo Solusi:
    echo 1. Download Node.js dari: https://nodejs.org/
    echo 2. Install Node.js LTS version
    echo 3. Restart command prompt
    echo 4. Jalankan script ini lagi
    echo.
    pause
    exit /b 1
)

echo [INFO] Node.js version:
node --version

REM Check if package.json exists
if not exist "package.json" (
    echo [ERROR] package.json tidak ditemukan!
    echo Pastikan Anda berada di direktori yang benar
    echo.
    pause
    exit /b 1
)

REM Check if node_modules exists
if not exist "node_modules\" (
    echo [INFO] node_modules tidak ditemukan, installing dependencies...
    echo [INFO] This may take 1-2 minutes...
    npm install
    if %errorlevel% neq 0 (
        echo [ERROR] Gagal install dependencies!
        echo.
        echo Solusi:
        echo 1. Pastikan koneksi internet stabil
        echo 2. Coba: npm cache clean --force
        echo 3. Hapus package-lock.json dan coba lagi
        echo.
        pause
        exit /b 1
    )
    echo [SUCCESS] Dependencies installed successfully!
) else (
    echo [INFO] node_modules found, checking for updates...
    npm outdated --silent
)

REM Check if bot.js exists
if not exist "bot.js" (
    echo [ERROR] bot.js tidak ditemukan!
    echo File bot utama hilang atau rusak
    echo.
    pause
    exit /b 1
)

REM Display bot information
echo.
echo ===============================================
echo   BOT CONFIGURATION
echo ===============================================
echo Platform: Windows %PROCESSOR_ARCHITECTURE%
echo Node.js: 
node --version
echo Working Directory: %CD%
echo Bot File: bot.js
echo Configuration: config.js
echo ===============================================
echo.

echo [INFO] Starting Pterodactyl Panel Installer Bot...
echo [INFO] Bot akan berjalan dengan enhanced error handling
echo [INFO] Press Ctrl+C to stop the bot
echo [INFO] Logs akan ditampilkan di console ini
echo.

REM Start the bot with enhanced error handling
:START_BOT
echo [%timestamp%] Attempting to start bot...
node bot.js

REM Check exit code
if %errorlevel% equ 0 (
    echo [INFO] Bot stopped normally
    goto :END
) else (
    echo [ERROR] Bot exited with error code: %errorlevel%
    echo.
    echo Possible issues:
    echo 1. Network connectivity problems
    echo 2. Invalid bot token
    echo 3. Missing dependencies
    echo 4. System resource constraints
    echo.
    
    choice /C YN /M "Do you want to restart the bot"
    if errorlevel 2 goto :END
    if errorlevel 1 (
        echo [INFO] Restarting bot in 3 seconds...
        timeout /t 3 /nobreak >nul
        goto :START_BOT
    )
)

:END
echo.
echo ===============================================
echo   BOT SHUTDOWN
echo ===============================================
echo Bot telah dihentikan
echo Terima kasih telah menggunakan bot ini!
echo.
echo Untuk troubleshooting:
echo 1. Cek koneksi internet
echo 2. Verifikasi bot token
echo 3. Pastikan dependencies up to date
echo 4. Hubungi developer jika masalah berlanjut
echo ===============================================
pause
