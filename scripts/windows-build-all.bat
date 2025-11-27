@echo off
REM HumanLayer Complete Build Script
REM Builds all components for production

setlocal enabledelayedexpansion

echo ========================================
echo  HumanLayer Complete Build Script
echo ========================================
echo.

REM Check if in correct directory
if not exist "hld" (
    echo ERROR: Please run this script from the repository root
    echo Current directory: %CD%
    pause
    exit /b 1
)

echo Building all components...
echo.

REM Build HLD Daemon
echo [1/4] Building HLD Daemon...
cd hld
go build -o hld-nightly.exe
if %ERRORLEVEL% NEQ 0 (
    echo ❌ HLD build failed
    cd ..
    pause
    exit /b 1
)
echo ✅ HLD daemon built: hld\hld-nightly.exe
cd ..

REM Build HLYR CLI
echo.
echo [2/4] Building HLYR CLI...
cd hlyr
call npm install
if %ERRORLEVEL% NEQ 0 (
    echo ❌ HLYR npm install failed
    cd ..
    pause
    exit /b 1
)
call npm run build
if %ERRORLEVEL% NEQ 0 (
    echo ❌ HLYR build failed
    cd ..
    pause
    exit /b 1
)
echo ✅ HLYR CLI built
cd ..

REM Install WUI dependencies
echo.
echo [3/4] Installing WUI dependencies...
cd humanlayer-wui
call bun install
if %ERRORLEVEL% NEQ 0 (
    echo ❌ WUI dependency installation failed
    cd ..
    pause
    exit /b 1
)
echo ✅ WUI dependencies installed
cd ..

REM Build WUI (Tauri desktop app)
echo.
echo [4/4] Building WUI desktop application...
echo This may take several minutes...
cd humanlayer-wui
call npm run tauri build
if %ERRORLEVEL% NEQ 0 (
    echo ❌ WUI build failed
    cd ..
    pause
    exit /b 1
)
echo ✅ WUI desktop app built
cd ..

echo.
echo ========================================
echo  ✅ Build Complete!
echo ========================================
echo.
echo 📦 Build artifacts:
echo    - HLD Daemon: hld\hld-nightly.exe
echo    - HLYR CLI: hlyr\dist\
echo    - WUI Installer: humanlayer-wui\src-tauri\target\release\bundle\nsis\
echo.
echo 📝 Next steps:
echo    1. Install WUI from NSIS installer
echo    2. Copy hld-nightly.exe to desired location
echo    3. Run: hld-nightly.exe
echo.
echo See WINDOWS_DEPLOYMENT.md for detailed instructions
echo.
pause

