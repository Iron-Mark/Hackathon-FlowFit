@echo off
echo ========================================
echo Testing Phone App
echo ========================================
echo.

echo Building and installing on phone (22101320G)...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_phone.ps1" -Device 6ece264d -Release

echo.
echo ========================================
echo Phone app deployed!
echo ========================================
