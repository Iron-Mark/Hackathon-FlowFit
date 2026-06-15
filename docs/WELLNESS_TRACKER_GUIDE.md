# Wellness Tracker - User Guide

## Quick Start

### Accessing the Wellness Tracker
1. Open the FlowFit app
2. Navigate to the **Track Tab** (bottom navigation)
3. Tap the **"Wellness Tracker"** button

### First-Time Setup
On your first visit, you'll see a 3-step onboarding:

**Step 1: Introduction**
- Learn about wellness monitoring
- Understand what data is collected

**Step 2: Features**
- Stress relief routes
- Exercise detection
- Daily insights

**Step 3: Setup**
- Grant body sensors permission
- Grant location permission for routes and geofence missions
- Verify watch connection
- Tap "Get Started"

---

## Features

### 1. Real-Time Wellness Monitoring

The app continuously monitors your wellness state:

- **😌 CALM**: Relaxed and at ease (HR < 90 BPM)
- **😰 STRESS**: Elevated stress detected (HR > 100 BPM + low motion)
- **💪 CARDIO**: Active exercise detected (HR > 100 BPM + high motion)

### 2. Stress Detection & Response

When stress is detected:
1. Alert banner appears at top of screen
2. Message: "High stress levels detected. Recommendation: Take a walk to clear your mind."
3. Three options:
   - **Show Routes**: View calming walking routes
   - **Not Now**: Snooze for 30 minutes
   - **Dismiss**: Close the alert

### 3. Calming Routes

When you tap "Show Routes":
- Map displays 3 walking routes near you
- FlowFit asks before requesting location permission; foreground geofence
  mission progress uses location while the app is open.
- Routes are scored based on:
  - Green space (parks, gardens)
  - Low traffic areas
  - Safety and lighting
  - Scenic value
- Tap a route to see details:
  - Distance (km)
  - Duration (minutes)
  - Green space percentage

### 4. Exercise Detection

When cardio activity is detected:
1. Banner appears: "Exercise detected! Keep it up! 💪"
2. Shows your current heart rate
3. Options to start tracking:
   - **Run**: Track as running workout
   - **Walk**: Track as walking workout
   - **Cycle**: Track as cycling workout
   - **No Thanks**: Continue monitoring only

### 5. Daily Statistics

View your wellness summary:
- **Calm Duration**: Hours spent in calm state
- **Active Duration**: Hours spent exercising
- **Stress Duration**: Minutes of detected stress
- **Timeline**: Visual bar chart of your day
- **Insights**: Personalized recommendations

---

## Settings

Access settings by tapping the ⚙️ icon in the app bar.

### Monitoring
- **Enable Wellness Monitoring**: Toggle on/off
- Monitoring persists across app restarts

### Notifications
- **Stress Alerts**: Enable/disable stress notifications
- **Exercise Detection**: Enable/disable cardio alerts
- **Alert Frequency**: Set minimum time between alerts
  - 15 minutes
  - 30 minutes (default)
  - 1 hour
  - 2 hours

### Privacy
- **Data Privacy**: Live wellness state is calculated on-device; saved
  account, workout, heart-rate, and mission records can sync to Supabase over
  HTTPS
- **Clear Wellness History**: Delete all stored data
- **Privacy Policy**: Learn about data protection

---

## Privacy & Data

### What We Collect
- Heart rate measurements
- Movement/activity data
- Location for routes, walking paths, and geofence missions
- Wellness state transitions
- Usage timestamps

### Your Privacy
✓ Live wellness state is calculated on your device
✓ Saved records can sync to Supabase over HTTPS
✓ You can delete your data anytime  
✓ No personal information shared  

---

## Troubleshooting

### "Watch not connected" Error

**Solutions:**
1. Check if your Samsung Galaxy Watch is paired
2. Open Galaxy Wearable app and verify connection
3. Restart Bluetooth on both devices
4. Try reconnecting the watch

### "Permission denied" Error

**Solutions:**
1. Go to Settings → Apps → FlowFit → Permissions
2. Enable "Body Sensors" permission
3. Restart the app
4. Try accessing wellness tracker again

### Routes not loading

**Solutions:**
1. Check your internet connection
2. Enable location services
3. Grant location permission to FlowFit
4. Try again in a few moments

### Battery draining quickly

**Tips:**
1. Reduce alert frequency in settings
2. Close other apps running in background
3. Ensure watch firmware is up to date
4. Expected battery impact: < 5% per hour

---

## Debug Mode (Developers Only)

In debug builds, a purple bug icon appears in the bottom right.

### Debug Panel Features:
- **Current State Display**: Real-time metrics
- **Mock State Override**: Test CALM/STRESS/CARDIO states
- **Sensor Simulation**: Adjust HR and motion with sliders
- **Test Scenarios**: Quick buttons for common tests
  - Simulate stress
  - Simulate exercise
  - Simulate calm
  - Simulate watch disconnect

---

## Tips for Best Results

### For Accurate Stress Detection:
- Wear your watch snugly (not too tight)
- Keep watch sensors clean
- Ensure watch is charged
- Stay still for 30 seconds when resting

### For Exercise Detection:
- Start moving with elevated heart rate
- Detection is immediate (no delay)
- Works for running, walking, cycling

### For Calming Routes:
- Enable location services for better routes
- Routes update based on your current location
- Green space percentage indicates nature exposure

---

## FAQ

**Q: How often does the app check my wellness state?**  
A: Continuously, with state updates every 1-2 seconds.

**Q: Will this drain my watch battery?**  
A: Battery impact is minimal (< 5% per hour). The app uses efficient buffering.

**Q: Can I use this without a Samsung Galaxy Watch?**  
A: Currently, a Samsung Galaxy Watch is required for heart rate monitoring.

**Q: Is my data shared with anyone?**  
A: FlowFit calculates live wellness state on your device. Account, workout,
heart-rate, and mission records can sync to Supabase over HTTPS for app
features and account recovery.

**Q: Can I export my wellness data?**  
A: Export is not implemented yet. You can request account and associated app
data deletion from the in-app Delete Account screen or public deletion page.

**Q: How accurate is stress detection?**  
A: The algorithm uses validated thresholds (HR > 100 BPM + low motion). Accuracy improves over time as you use the feature.

**Q: Why do I need to wait 30 seconds for stress detection?**  
A: This prevents false positives. Brief heart rate spikes (like standing up) won't trigger alerts.

**Q: Can I customize the heart rate thresholds?**  
A: Currently, thresholds are fixed based on research. Custom thresholds may be added in future updates.

---

## Support

For issues or questions:
1. Check this guide first
2. Review troubleshooting section
3. Check app settings
4. Contact support through the app

---

**Last Updated**: November 27, 2025  
**Version**: 1.0.0  
**Feature Status**: Production Ready ✅
