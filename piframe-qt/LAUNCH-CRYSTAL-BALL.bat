@echo off
echo.
echo ================================================
echo    LAUNCHING CRYSTAL BALL DEMO
echo ================================================
echo.
echo Loading your P: drive photos...
echo Press 'B' to toggle Crystal Ball mode
echo.

cd /d "%~dp0\release"
piframe-qt.exe --dev --config "..\config\config-test.json"

pause
