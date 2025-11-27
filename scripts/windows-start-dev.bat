@echo off
REM HumanLayer Development Environment Starter
REM Starts daemon and UI in development mode

setlocal enabledelayedexpansion

echo ========================================
echo  HumanLayer Development Environment
echo ========================================
echo.

REM Check if in correct directory
if not exist "hld" (
    echo ERROR: Please run this script from the repository root
    echo Current directory: %CD%
    pause
    exit /b 1
)

echo Starting development environment...
echo.

REM Check for Windows Terminal
where wt >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Using Windows Terminal for split view...
    
    REM Start Windows Terminal with split panes
    wt -w 0 new-tab --title "HumanLayer Dev" ^
        -d "%CD%\hld" cmd /k "echo Starting HLD Daemon (Dev Mode)... && go run . --socket "%USERPROFILE%\.humanlayer\daemon-dev.sock" --db "%USERPROFILE%\.humanlayer\daemon-dev.db"" ^
        ; split-pane -V -d "%CD%\humanlayer-wui" cmd /k "echo Starting WUI (Dev Mode)... && timeout /t 3 /nobreak >nul && npm run tauri dev" ^
        ; split-pane -H -d "%CD%" cmd /k "echo Claude Code CLI Ready. Use: npx humanlayer launch \"your task\" && cmd /k"
        
    echo.
    echo ✅ Started in Windows Terminal
    echo    - Left pane: HLD Daemon
    echo    - Right top: WUI
    echo    - Right bottom: CLI
    echo.
) else (
    echo Windows Terminal not found, starting in separate windows...
    
    REM Start daemon in new window
    start "HLD Daemon (Dev)" cmd /k "cd /d %CD%\hld && echo Starting HLD Daemon... && go run . --socket "%USERPROFILE%\.humanlayer\daemon-dev.sock" --db "%USERPROFILE%\.humanlayer\daemon-dev.db""
    
    REM Wait a moment for daemon to start
    timeout /t 3 /nobreak >nul
    
    REM Start WUI in new window
    start "HumanLayer WUI (Dev)" cmd /k "cd /d %CD%\humanlayer-wui && echo Starting WUI... && npm run tauri dev"
    
    echo.
    echo ✅ Started in separate windows
    echo    Check taskbar for:
    echo    - "HLD Daemon (Dev)"
    echo    - "HumanLayer WUI (Dev)"
    echo.
)

echo Development environment is starting...
echo.
echo 📝 Next steps:
echo    1. Wait for WUI to open
echo    2. Run: npx humanlayer launch "your task"
echo.
echo 📚 Logs:
echo    Daemon: %USERPROFILE%\.humanlayer\logs\daemon-dev-*.log
echo    WUI: %USERPROFILE%\.humanlayer\logs\wui-dev\codelayer.log
echo.
echo Press any key to exit...
pause >nul

