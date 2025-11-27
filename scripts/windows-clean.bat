@echo off
REM HumanLayer Cleanup Script
REM Removes build artifacts and temporary files

setlocal enabledelayedexpansion

echo ========================================
echo  HumanLayer Cleanup Script
echo ========================================
echo.

set /p confirm="This will remove all build artifacts. Continue? (y/N): "
if /i not "%confirm%"=="y" (
    echo Cancelled.
    exit /b 0
)

echo.
echo Cleaning up...
echo.

REM Clean HLD
if exist "hld\hld.exe" (
    echo Removing hld\hld.exe
    del /f /q "hld\hld.exe"
)
if exist "hld\hld-nightly.exe" (
    echo Removing hld\hld-nightly.exe
    del /f /q "hld\hld-nightly.exe"
)
if exist "hld\hld-dev.exe" (
    echo Removing hld\hld-dev.exe
    del /f /q "hld\hld-dev.exe"
)

REM Clean HLYR
if exist "hlyr\dist" (
    echo Removing hlyr\dist\
    rmdir /s /q "hlyr\dist"
)
if exist "hlyr\node_modules" (
    echo Removing hlyr\node_modules\
    rmdir /s /q "hlyr\node_modules"
)

REM Clean WUI
if exist "humanlayer-wui\src-tauri\target" (
    echo Removing humanlayer-wui\src-tauri\target\
    rmdir /s /q "humanlayer-wui\src-tauri\target"
)
if exist "humanlayer-wui\node_modules" (
    echo Removing humanlayer-wui\node_modules\
    rmdir /s /q "humanlayer-wui\node_modules"
)

REM Clean root node_modules
if exist "node_modules" (
    echo Removing root node_modules\
    rmdir /s /q "node_modules"
)

REM Clean Bun cache (optional)
set /p cleanBun="Remove Bun cache? (y/N): "
if /i "%cleanBun%"=="y" (
    if exist "%USERPROFILE%\.bun\install\cache" (
        echo Removing Bun cache...
        rmdir /s /q "%USERPROFILE%\.bun\install\cache"
    )
)

echo.
echo ========================================
echo  ✅ Cleanup Complete!
echo ========================================
echo.
echo Removed:
echo    - Build artifacts (*.exe)
echo    - Distribution folders
echo    - Node modules
echo.
echo Run setup again with:
echo    powershell -ExecutionPolicy Bypass -File .\scripts\windows-setup.ps1
echo.
pause

