# Map Missions - User Flow & Tutorial

## User Flow Overview

```
Tracker Page → Map Missions Button → Map View → Create Mission → Activate → Track Progress
```

## Step-by-Step User Flow

### 1. Starting Point: Activity Tracker
**Location**: Track Tab → Activity AI Classifier

**User sees**:
- Activity classification (Stress/Cardio/Strength)
- Heart rate monitoring
- Sensor data controls
- **NEW: Map icon button** in top-right corner

**Action**: User taps the map icon 🗺️

---

### 2. Map Missions Screen
**Location**: Wellness Map Page

**User sees**:
- Full-screen map centered on their current location
- Their location marker (blue dot with pulse)
- Bottom sheet with mission list
- Floating action buttons (+ and location center)

**First-time experience**:
- Map loads and requests location permission
- Centers on user's current GPS position
- Shows empty mission list (or sample mission)

---

### 3. Creating a Mission

#### Option A: Long-Press on Map
1. User **long-presses** anywhere on the map
2. Mission creation overlay appears
3. User sees:
   - Mission title input field
   - Mission type selector (Target/Sanctuary/Safety Net)
   - Radius slider (50m - 500m)
   - Target distance input (for Target missions)
   - Preview circle on map
4. User can **tap** to adjust location
5. User taps **"Confirm"** to create

#### Option B: Quick Add Button
1. User taps the **+ button** (floating action)
2. Mission is created at current location
3. Same creation overlay appears

---

### 4. Mission Types Explained

#### 🎯 Target Mission (Fitness)
**Setup**:
- Title: "Morning Walk"
- Type: Target
- Radius: 100m (detection zone)
- Target Distance: 500m

**How it works**:
1. User activates the mission
2. Walks away from the starting point
3. App tracks cumulative distance
4. Notification when 500m is reached
5. Mission completes ✅

**Use case**: Daily walking goals, exploration challenges

---

#### 🧘 Sanctuary Mission (Mental Health)
**Setup**:
- Title: "City Park"
- Type: Sanctuary
- Radius: 50m
- Location: Park coordinates

**How it works**:
1. User activates the mission
2. Travels toward the sanctuary
3. When entering the 50m radius → Success! 🎉
4. Optional: Trigger journaling prompt

**Use case**: Visit peaceful places, social locations, break routine

---

#### 🛡️ Safety Net Mission (Safety)
**Setup**:
- Title: "Home Safety Zone"
- Type: Safety Net
- Radius: 200m
- Location: Home address

**How it works**:
1. User (or caregiver) activates the mission
2. App monitors if user stays within 200m
3. If user exits the zone → Alert notification! ⚠️
4. Caregiver gets notified

**Use case**: Elderly monitoring, child safety, recovery tracking

---

### 5. Managing Missions

#### From Mission List (Bottom Sheet)
**User can**:
- View all missions
- See active/inactive status
- Tap mission to see details
- Swipe to see more options

#### Mission Actions Menu
When tapping a mission:
- **Activate** - Start tracking this mission
- **Deactivate** - Stop tracking
- **Edit** - Change title, radius, type
- **Focus & Navigate** - Full-screen navigation mode
- **Delete** - Remove mission

---

### 6. Focus & Navigate Mode

**When user taps "Focus & Navigate"**:

**Screen shows**:
- Large mission card overlay
- Real-time distance to target
- Estimated time of arrival (ETA)
- Speed adjustment slider
- Center button (re-center map on mission)
- Activate/Deactivate toggle

**Live updates**:
- Distance updates every 5 seconds
- ETA recalculates based on speed
- Map follows user's movement

**Example**:
```
🎯 Morning Walk
Distance: 234m / 500m
ETA: 3 min 45 sec
Speed: 1.4 m/s (walking)

[Center on Mission] [Deactivate]
```

---

### 7. Notifications & Alerts

#### Mission Events:
- **Entered Zone**: "You've entered [Mission Name]"
- **Exited Zone**: "You've left [Mission Name]"
- **Target Reached**: "[Mission Name] - 500m completed! 🎉"
- **Outside Alert**: "[Mission Name] - You're 250m outside the safe zone ⚠️"

#### Foreground Tracking:
- Missions track progress while the app is open and location access is active
- Native background geofencing is not part of the release build yet
- Closed-app mission tracking stays future work until native background delivery is implemented and tested

---

## Complete User Journey Example

### Scenario: Daily Walking Challenge

**Day 1 - Setup**:
1. User opens Activity Tracker
2. Taps map icon
3. Long-presses on map near home
4. Creates "Morning Walk" mission:
   - Type: Target
   - Radius: 100m
   - Target: 500m
5. Taps "Confirm"

**Day 1 - First Walk**:
1. User taps mission in list
2. Taps "Focus & Navigate"
3. Taps "Activate"
4. Starts walking away from home
5. Watches distance increase: 100m... 250m... 400m...
6. Gets notification: "Morning Walk - 500m completed! 🎉"
7. Mission auto-deactivates

**Day 2 - Repeat**:
1. User opens map
2. Taps "Morning Walk"
3. Taps "Activate"
4. Completes walk again
5. Builds streak! 🔥

---

## Integration with Activity Tracker

### Why the Map Button is in Tracker:

1. **Context**: User is already thinking about activity/exercise
2. **Flow**: Natural progression from monitoring → planning → executing
3. **Data Connection**: Activity data + location data = complete picture

### Suggested Workflow:

```
Morning Routine:
1. Check Activity Tracker (see yesterday's stats)
2. Open Map Missions
3. Activate "Morning Walk" mission
4. Go for walk
5. Return to Activity Tracker to see results
```

---

## Permissions Required

### Location Permissions:
- **When In Use**: Required for map display and mission creation
- **Always/Background**: Not requested in release builds; closed-app mission tracking is unavailable until native background geofencing is implemented and tested.

### Permission Flow:
1. First map open shows the FlowFit location rationale.
2. Continuing requests foreground "When In Use" location.
3. User can manage the permission in Settings.

### Android Specific:
- Release builds use foreground fine/coarse location only.
- Android 12+: Approximate vs Precise location options

### iOS Specific:
- "Allow While Using App"
- User can change in Settings → Privacy → Location

---

## Tips for Best Experience

### For Users:
1. **Start Simple**: Create one Target mission first
2. **Test Locally**: Walk around your block to test
3. **Adjust Radius**: If missions trigger too early/late, adjust radius
4. **Use Focus Mode**: For active missions, use Focus & Navigate
5. **Check Notifications**: Enable notifications for mission alerts

### For Caregivers (Safety Net):
1. Set up Safety Net mission on user's device
2. Test by walking to edge of zone
3. Verify you receive alerts
4. Adjust radius based on needs
5. Check battery usage (should be minimal)

---

## Troubleshooting

### Map not loading?
- Check internet connection (needs to download map tiles)
- Verify location permissions granted
- Try tapping the center location button

### Mission not triggering?
- Ensure mission is activated (green indicator)
- Check radius isn't too small
- Keep FlowFit open; release geofence missions are foreground-only
- Check battery saver isn't blocking location

### Distance not tracking?
- For Target missions, ensure you're moving away from center
- Check GPS signal (works better outdoors)
- Verify mission is active

### Battery draining?
- Missions use foreground location updates while FlowFit is open
- Deactivate missions when not needed
- Reduce number of active missions
- Check other apps using location

---

## Future Enhancements

### Planned Features:
- [ ] Mission templates (quick setup)
- [ ] Mission sharing (send to friends)
- [ ] Achievement badges
- [ ] Weekly challenges
- [ ] Route recording
- [ ] Social features (compete with friends)
- [ ] Integration with fitness goals
- [ ] Custom notification sounds
- [ ] Mission history/stats

---

## Developer Notes

### Current Implementation:
- In-memory storage (missions lost on app restart)
- Foreground location tracking
- Basic geofencing from the active location stream
- OpenStreetMap tiles (no API key needed)

### Production Readiness Checklist:
- [ ] Replace in-memory repo with persistent storage
- [ ] Implement native background geofencing before requesting background location
- [ ] Add mission data sync (cloud backup)
- [ ] Implement proper error handling
- [ ] Add analytics tracking
- [ ] Test on various Android versions
- [ ] Test battery impact
- [ ] Add onboarding tutorial
- [ ] Implement mission templates
- [ ] Add accessibility features

---

## Quick Reference

### Gestures:
- **Long-press**: Create mission at location
- **Tap**: Select mission marker
- **Pinch**: Zoom in/out
- **Drag**: Pan map

### Buttons:
- **+ (Floating)**: Quick add mission at current location
- **📍 (Floating)**: Center map on current location
- **Map Icon (Tracker)**: Open map missions
- **Back Arrow**: Return to previous screen

### Mission Status:
- **Green**: Active and tracking
- **Gray**: Inactive
- **Blue**: Currently focused

### Colors:
- **Blue**: Current location
- **Green**: Sanctuary missions
- **Orange**: Target missions
- **Red**: Safety Net missions
