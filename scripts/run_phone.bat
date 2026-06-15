@echo off
echo ========================================
echo FlowFit - Run on Android Phone
echo ========================================
echo.
echo Device: 22101320G (6ece264d)
echo Entry: lib/main.dart
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_phone.ps1" -Device 6ece264d
