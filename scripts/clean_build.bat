@echo off
echo Cleaning Flutter build cache...
flutter clean
echo.
echo Getting dependencies...
flutter pub get
echo.
echo Build cache cleared! Now run:
echo scripts\run_phone.bat
pause
