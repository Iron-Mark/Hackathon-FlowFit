# Map Feature Guide - Wellness Mission Engine

## What is This Feature?

The map feature is a **location-based mission system** that helps users achieve wellness goals through geofencing. It combines GPS tracking with motivational missions to encourage physical activity, mental health practices, and safety monitoring.

## Why Implement This?

### 1. **Fitness Motivation** 
Instead of just tracking steps, users get **goal-oriented missions** that make exercise more engaging:
- "Walk 500m from your starting point"
- "Explore a 1km radius around your neighborhood"
- Gamifies outdoor activity with clear objectives

### 2. **Mental Health Support**
Encourages users to visit calming locations:
- Set a "sanctuary" at a park, beach, or favorite spot
- Get reminded to visit peaceful places
- Track visits to mental health-supporting locations

### 3. **Safety & Elderly Care**
Provides peace of mind for caregivers:
- Set a "safety net" around home or safe area
- Get alerts if someone leaves the safe zone
- Useful for elderly users, children, or people with cognitive conditions

## Three Mission Types

### 🎯 Target Mission (Fitness)
**Purpose**: Encourage distance-based exercise

**How it works**:
- Set a starting point (usually current location)
- Define a target distance (e.g., 500 meters)
- As you move away from the center, distance accumulates
- Mission completes when you reach the target

**Example**: "Neighborhood Walk" - Walk 500m from home
```
Starting Point: Your home
Radius: 100m (detection zone)
Target: 500m total distance
```

**Use Case**: 
- Daily walking goals
- Exploration challenges
- Progressive distance training

---

### 🧘 Sanctuary Mission (Mental Health)
**Purpose**: Encourage visits to calming locations

**How it works**:
- Mark a location you want to visit (park, cafe, friend's house)
- Set a radius around it
- When you enter the zone, mission succeeds
- Can trigger journaling prompts or mindfulness exercises

**Example**: "Visit the Park" - Go to your local park
```
Location: City Park
Radius: 50m
Goal: Enter the zone
```

**Use Case**:
- Encourage outdoor time
- Visit social locations
- Break from routine
- Mindfulness practice locations

---

### 🛡️ Safety Net Mission (Safety/Elderly)
**Purpose**: Monitor safe zone boundaries

**How it works**:
- Define a safe area (home, neighborhood)
- Set a radius for the safe zone
- Get alerts if the user leaves the zone
- Useful for monitoring vulnerable individuals

**Example**: "Home Safety Zone" - Stay within 200m of home
```
Location: Home address
Radius: 200m
Alert: If user exits the zone
```

**Use Case**:
- Elderly care monitoring
- Child safety tracking
- Dementia patient support
- Recovery monitoring

## Real-World Use Cases

### For Fitness Users:
1. **Daily Walking Challenge**: Create a 1km target mission from home each morning
2. **Neighborhood Explorer**: Set multiple sanctuary missions at interesting local spots
3. **Progressive Training**: Increase target distances weekly

### For Mental Health:
1. **Peaceful Places**: Mark parks, beaches, or quiet spots as sanctuaries
2. **Social Connections**: Set sanctuaries at friends' homes to encourage visits
3. **Routine Breaking**: Create missions to visit new places

### For Caregivers:
1. **Elderly Monitoring**: Set safety net around parent's home
2. **Wandering Prevention**: Get alerts if someone with dementia leaves safe area
3. **Child Safety**: Monitor kids' location boundaries

### For General Wellness:
1. **Work-Life Balance**: Create sanctuary at gym or hobby location
2. **Habit Building**: Visit healthy locations (gym, healthy restaurant)
3. **Adventure Motivation**: Explore new areas with target missions

## Technical Features

- **Map Tiles**: Uses CARTO Voyager by default through
  `FLOWFIT_MAP_TILE_URL_TEMPLATE`; use a production-appropriate provider and
  avoid public `tile.openstreetmap.org` traffic for releases.
- **Foreground Tracking**: Monitors mission progress while the app is open
- **Mission Alerts**: Shows in-app status for mission events
- **Backend Sync**: Saved wellness records can sync to Supabase when configured
- **Battery Scoped**: Release builds avoid closed-app location tracking until native background geofencing is implemented and tested

## Sample Mission: "Neighborhood Walk"

The demo mission shows:
```
Title: Neighborhood Walk
Type: Target (Fitness)
Location: 37.4219999, -122.0840575 (Google HQ - just for demo)
Radius: 100m (detection zone)
Target Distance: 500m
```

**What happens**:
1. User activates the mission
2. App tracks distance as they walk away from center
3. When 500m is reached, mission completes
4. User gets notification of success

## Why Your Friend Added This

Your friend likely added this because:

1. **Differentiation**: Most fitness apps just count steps - this adds **purpose** and **gamification**
2. **Multi-Use**: One feature serves fitness, mental health, AND safety needs
3. **Engagement**: Location-based missions are more engaging than passive tracking
4. **Modern Trend**: Apps like Pokémon GO proved location-based features drive engagement
5. **Practical Value**: Real safety monitoring for elderly/vulnerable users

## Should You Keep It?

**Keep it if**:
- You want to differentiate from basic fitness trackers
- Your target users include caregivers or elderly
- You want gamification elements
- You're building a comprehensive wellness app

**Remove it if**:
- You only need basic step counting
- Privacy concerns about location tracking
- You want to minimize app complexity
- Battery usage is a major concern

## Next Steps

If keeping this feature:
1. Replace the sample mission with user's actual location
2. Add persistent storage (currently in-memory only)
3. Implement native background geofencing before adding background location
   permissions
4. Add mission templates for quick setup
5. Create onboarding tutorial explaining the feature

If removing:
1. Delete `lib/features/wellness/` folder
2. Remove map dependencies from `pubspec.yaml`
3. Remove `/mission` route from `main.dart`
4. Remove map button from tracker page
