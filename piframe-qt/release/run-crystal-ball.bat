@echo off
REM PiFrame Qt Crystal Ball Demo Launcher
REM Press 'B' to toggle crystal ball mode
REM Press 'C' to toggle clock
REM Press 'SPACE' for next photo
REM Press 'ESC' to quit

echo =========================================
echo   PiFrame Qt - Crystal Ball Demo
echo =========================================
echo.
echo Keyboard Controls:
echo   B       = Toggle Crystal Ball Mode
echo   C       = Toggle Clock Overlay
echo   SPACE   = Next Photo
echo   P       = Play/Pause
echo   ESC     = Quit
echo.
echo Starting in 2 seconds...
timeout /t 2 /nobreak >nul

cd /d "%~dp0"
start "" "piframe-qt.exe" --dev --config "../config/config-test.json"

echo.
echo Application launched!
echo Check the window for the crystal ball effect.
echo.
pause
