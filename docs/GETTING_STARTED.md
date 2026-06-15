# Getting Started with FlowFit

Quick guide to get you up and running with FlowFit development.

## 🎯 What is FlowFit?

FlowFit is a health and fitness tracking app that runs on:
- **Galaxy Watch** (Wear OS) - Primary device for real-time tracking
- **Android Phone** - Companion app for data visualization

## 🚀 Quick Start (5 Minutes)

### 1. Prerequisites

**Hardware**:
- Galaxy Watch4 or higher
- Android phone
- Both devices paired

**Software**:
- Flutter SDK installed
- Android Studio
- ADB working

### 2. Clone & Setup

```bash
# Clone repository
git clone <repository-url>
cd flowfit

# Install dependencies
flutter pub get

# Configure Supabase
# Preferred: pass SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY with --dart-define
# Optional script fallback: copy lib/secrets.dart.example to lib/secrets.dart
```

### 3. Connect Devices

```bash
# Check devices are connected
adb devices

# Should show:
# 6ece264d        device  (watch)
# adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp    device  (phone)
```

### 4. Build & Run

```bash
# Option A: Use automated script (recommended)
scripts\build_and_install.bat

# Option B: Manual run
flutter run -d 6ece264d
```

### 5. Approve Installation

**Important**: When installing on watch, you must:
1. Watch will show "Install app?" prompt
2. Tap "Install" button
3. Must approve within 30 seconds

### 6. Test Heart Rate

1. Open app on watch
2. Grant "Body sensors" permission
3. Tap "Connect" button
4. Tap "Start" button
5. Wear watch on wrist
6. Wait 5-10 seconds for readings

## 📚 Next Steps

### Learn More

1. **[Quick Start Guide](docs/QUICK_START.md)** - Detailed 5-minute guide
2. **[Samsung Health Setup](docs/SAMSUNG_HEALTH_SETUP_GUIDE.md)** - Complete integration guide
3. **[Project Structure](PROJECT_STRUCTURE.md)** - Understand the codebase

### Common Tasks

**Run on watch**:
```bash
scripts\run_watch.bat
```

**Run on phone**:
```bash
scripts\run_phone.bat
```

**View logs**:
```bash
adb -s 6ece264d logcat | findstr "FlowFit"
```

**Clean build**:
```bash
flutter clean
flutter pub get
```

### Troubleshooting

**Installation fails?**
→ See [Installation Troubleshooting](docs/INSTALLATION_TROUBLESHOOTING.md)

**Build errors?**
→ See [Build Fixes Applied](docs/BUILD_FIXES_APPLIED.md)

**Need help?**
→ Check [Documentation Index](docs/README.md)

## 🗂️ Project Organization

```
flowfit/
├── docs/        # 📚 All documentation
├── scripts/     # 🔧 Build and run scripts
├── lib/         # Flutter source code
├── android/     # Android native code
└── README.md    # Main documentation
```

**See [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) for complete structure.**

## 🎯 Development Workflow

### Daily Development

1. **Make changes** in `lib/` folder
2. **Run on watch**: `scripts\run_watch.bat`
3. **Use hot reload**: Press `r` in terminal
4. **View logs**: `adb -s 6ece264d logcat | findstr "FlowFit"`

### After Major Changes

1. **Clean build**: `flutter clean`
2. **Get dependencies**: `flutter pub get`
3. **Build and install**: `scripts\build_and_install.bat`

### Before Committing

1. **Run analyzer**: `flutter analyze`
2. **Run tests**: `flutter test`
3. **Update docs** if needed
4. **Check `.gitignore`**

## 🔧 Key Features to Explore

### Heart Rate Monitoring
- Real-time heart rate tracking
- Inter-beat interval (IBI) data
- Heart rate variability (HRV)

**Code**: `lib/services/watch_bridge.dart`

### Activity Tracking
- Workout logging
- Exercise monitoring
- Calorie tracking

**Code**: `lib/screens/workout/activity_tracker.dart`

### Sleep Tracking
- Sleep mode
- Sleep quality analysis
- Wake detection

**Code**: `lib/screens/sleep/sleep_mode.dart`

### Data Sync
- Watch → Phone transfer
- Supabase backend sync
- Real-time updates

**Code**: `lib/services/supabase_service.dart`

## 📱 Device Information

### Watch (Primary)
- **Device ID**: `6ece264d`
- **Model**: Galaxy Watch (22101320G)
- **Run**: `flutter run -d 6ece264d`

### Phone (Companion)
- **Device ID**: `adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp`
- **Run**: `flutter run -d adb-RFAX21TD0NA-FFYRNh._adb-tls-connect._tcp`

## 🐛 Common Issues

### "Device not found"
```bash
# Check connection
adb devices

# Restart ADB
adb kill-server
adb start-server
```

### "Permission denied"
```bash
# Enable on watch:
# Settings → Developer options → ADB debugging → ON
```

### "Build failed"
```bash
# Clean and rebuild
flutter clean
flutter pub get
scripts\build_and_install.bat
```

### "No heart rate data"
- Wear watch on wrist (sensor needs skin contact)
- Tighten watch band
- Wait 5-10 seconds for stabilization

## 📚 Documentation

### Essential Reading
1. [README.md](README.md) - Project overview
2. [docs/QUICK_START.md](docs/QUICK_START.md) - Quick start guide
3. [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) - Project structure

### Full Documentation
See [docs/README.md](docs/README.md) for complete documentation index.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 💡 Tips

- **Use scripts** for common tasks (saves time)
- **Check logs** regularly for errors
- **Keep watch charged** (>20% battery)
- **Wear watch properly** for accurate readings
- **Read documentation** before asking questions

## 🎉 You're Ready!

You now have everything you need to start developing with FlowFit.

**Next command to run**:
```bash
scripts\build_and_install.bat
```

Remember to approve the installation on your watch!

---

**Need help?** Check the [documentation](docs/README.md) or open an issue.
