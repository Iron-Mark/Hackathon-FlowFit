# FLOWFIT KIDS: SINGLE PET WITH COLOR CUSTOMIZATION

## 📋 PROJECT OVERVIEW

FlowFit Kids is a Flutter-based wellness and fitness tracking application for children aged 7-12. The app uses **Buddy**, a customizable companion pet, to promote healthy habits through gamification and kid-friendly UX with full parental oversight.

### Technology Stack

- **Framework**: Flutter (iOS, Android, Wear OS)
- **Backend**: Supabase (authentication, database, real-time features)
- **State Management**: Provider pattern
- **Native Integration**: Samsung Health SDK (via MethodChannel/EventChannel)
- **Platform Support**: iOS, Android, Web, Windows, macOS, Linux

### Safety & Privacy First

- **COPPA Compliant**: Minimal data collection, parental consent required
- **Ad-Free**: No advertisements or in-app purchases
- **Parental Controls**: Activity monitoring, privacy settings, content filtering
- **Data Protection**: Minimal data collection, secure storage in Supabase
- **Content Safety**: Age-appropriate challenges, filtered social features

---

## 🎨 SIMPLIFIED PET SYSTEM

### Single Pet Design: "Buddy" (The FlowFit Companion)

Instead of multiple pet types, we have **ONE adorable pet character** that children can customize with colors.

**Character Traits:**

```
Shape: Rounded, soft, friendly (blob/bean shape)
Style: Simple geometric shapes (easy to animate)
Features:
  - Large expressive eyes
  - Small arms and legs
  - Round body
  - Optional tail (small, curved)
  - Smooth edges (kid-friendly)
```

---

## 🎯 ONBOARDING FLOW (90 SECONDS!)

```
┌─────────────────────────────────────────┐
│ 1. Welcome Screen                       │
│    "Meet Your Fitness Buddy!"           │
│    [Animated Buddy character bouncing]  │
│    [LET'S GO!] button                   │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│ 2. Meet Your Buddy! 🎨                 │
│                                         │
│    [Large Buddy in Ocean Blue]          │
│    "Hi! I'm your fitness buddy!"        │
│                                         │
│    💙 Ocean Blue (Your starting color) │
│                                         │
│    Earn more colors as you level up!   │
│                                         │
│    🐚 Teal at Level 3                  │
│    🟢 Green at Level 5                 │
│    🟣 Purple at Level 8                │
│    ... and more!                        │
│                                         │
│    [LET'S GO!] button                  │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│ 3. Name Your Buddy                      │
│    "What will you call your buddy?"     │
│                                         │
│    [Text input - big, friendly]         │
│                                         │
│    💡 Ideas: Sparky, Flash, Star       │
│                                         │
│    [THAT'S PERFECT!] button             │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│ 4. Quick About You                      │
│    "Tell Buddy about yourself!"         │
│                                         │
│    Your Nickname: [___________]         │
│                                         │
│    Your Age:                            │
│    ┌───┐┌───┐┌───┐┌───┐┌───┐┌───┐    │
│    │ 7 ││ 8 ││ 9 ││10 ││11 ││12 │    │
│    └───┘└───┘└───┘└───┘└───┘└───┘    │
│                                         │
│    [SKIP] or [CONTINUE]                 │
└─────────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────────┐
│ 5. 🎉 Buddy is Ready!                   │
│                                         │
│    [Buddy jumps with excitement]        │
│                                         │
│    "Sparky wants to play!              │
│     Let's do your first challenge!"     │
│                                         │
│    [START FIRST MISSION] button         │
└─────────────────────────────────────────┘
```

---

## 🎨 COLOR CUSTOMIZATION SYSTEM

### Available Colors (Simplified Palette)

**Design Philosophy**: Start with a calming blue-centered palette to avoid overwhelming children with too many bright colors at once. Colors unlock gradually to maintain excitement and progression.

```dart
class BuddyColors {
  static const Map<String, Color> colors = {
    // Default - Always available
    'blue': Color(0xFF4ECDC4),     // Ocean Blue (DEFAULT)

    // Early unlocks - Complementary to blue
    'teal': Color(0xFF26A69A),     // Calm Teal (Level 3)
    'green': Color(0xFF66BB6A),    // Fresh Green (Level 5)

    // Mid-tier unlocks - Expanding palette
    'purple': Color(0xFF9575CD),   // Soft Purple (Level 8)
    'yellow': Color(0xFFFFD54F),   // Gentle Yellow (Level 10)

    // Advanced unlocks - Full color expression
    'orange': Color(0xFFFFB74D),   // Warm Orange (Level 15)
    'pink': Color(0xFFF06292),     // Happy Pink (Level 20)
    'navy': Color(0xFF5C6BC0),     // Deep Navy (Level 25)
  };
}
```

### Color Unlock Progression

```
Starting Color (Default):
└─ Blue (Ocean Blue) - Calming, friendly default

Early Progression (Weeks 1-2):
├─ Level 3  → Teal unlocked (stays in blue family)
└─ Level 5  → Green unlocked (nature-friendly expansion)

Mid Progression (Weeks 3-4):
├─ Level 8  → Purple unlocked (creative expression)
└─ Level 10 → Yellow unlocked (cheerful energy)

Advanced Progression (Months 2-3):
├─ Level 15 → Orange unlocked (warmth & excitement)
├─ Level 20 → Pink unlocked (playful fun)
└─ Level 25 → Navy unlocked (mature achievement)

Special Achievement Colors (Optional - Future):
├─ 30-day streak   → Gradient effect (blue→green)
└─ 100 workouts    → Shimmer effect (subtle sparkle)
```

**Why Blue Default?**

- 🧠 **Calming Effect**: Blue reduces anxiety, ideal for kids starting a new app
- 👁️ **Visual Comfort**: Easiest color on the eyes, reduces cognitive load
- 🎨 **Design Consistency**: Matches existing FlowFit branding
- 🌊 **Universal Appeal**: Most popular color across age groups
- 📱 **Accessibility**: High contrast options with blue base

---

## 🎮 BUDDY PROGRESSION SYSTEM

### Growth Stages (Single Pet Evolution)

Instead of different pets, **Buddy evolves as the child progresses:**

```
┌─────────────────────────────────────────┐
│ Buddy's Growth Stages                   │
├─────────────────────────────────────────┤
│ Level 1-5:   Baby Buddy (Small, cute)   │
│ Level 6-10:  Kid Buddy (Medium, playful)│
│ Level 11-20: Teen Buddy (Bigger, sporty)│
│ Level 21-30: Super Buddy (Large, heroic)│
│ Level 31+:   Mega Buddy (Epic, glowing) │
└─────────────────────────────────────────┘
```

### Visual Changes by Stage

```dart
class BuddyStage {
  final int level;
  final String stage;
  final double size;        // Relative size multiplier
  final List<String> animations;
  final List<String> accessories;

  // Example stages
  static const stages = [
    BuddyStage(
      level: 1,
      stage: 'baby',
      size: 0.7,
      animations: ['bounce', 'wiggle', 'sleep'],
      accessories: [] // No accessories yet
    ),
    BuddyStage(
      level: 6,
      stage: 'kid',
      size: 1.0,
      animations: ['jump', 'run', 'dance', 'stretch'],
      accessories: ['cap', 'shoes']
    ),
    BuddyStage(
      level: 11,
      stage: 'teen',
      size: 1.3,
      animations: ['sprint', 'backflip', 'celebrate', 'power_pose'],
      accessories: ['cap', 'shoes', 'backpack', 'wristband']
    ),
    BuddyStage(
      level: 21,
      stage: 'super',
      size: 1.5,
      animations: ['fly', 'super_jump', 'energy_burst', 'victory'],
      accessories: ['cape', 'mask', 'belt', 'all_previous']
    ),
  ];
}
```

### Animation States

```dart
enum BuddyAnimation {
  idle,           // Gentle breathing, blinking
  happy,          // Jumping, smiling
  excited,        // Spinning, bouncing
  exercising,     // Running in place, jumping jacks
  tired,          // Slow movement, yawning
  sleeping,       // Eyes closed, "Z" particles
  celebrating,    // Confetti, stars, victory pose
  thinking,       // Question mark bubble
  encouraging,    // Thumbs up, motivational bounce
}
```

---

## 🎁 REWARD SYSTEM

### 1. Colors (Primary Rewards)

```
└─ 10 base colors
└─ 3 special effect colors (rainbow, golden, sparkle)
└─ Seasonal colors (event-based)
```

### 2. Accessories (Secondary Rewards)

```
Hats & Headwear:
├─ Baseball Cap (Level 3)
├─ Beanie (Level 7)
├─ Crown (Level 15)
└─ Superhero Mask (Level 20)

Clothing:
├─ T-shirt (Default)
├─ Sporty Jersey (Level 5)
├─ Hoodie (Level 10)
└─ Cape (Level 20)

Footwear:
├─ Sneakers (Level 4)
├─ Running Shoes (Level 8)
└─ Power Boots (Level 18)

Extras:
├─ Backpack (Level 6)
├─ Wristband (Level 9)
├─ Sunglasses (Level 12)
└─ Badge Collection (Various milestones)
```

### 3. Backgrounds (Environment Rewards)

```
├─ Home (Default)
├─ Park (Level 5)
├─ Beach (Level 10)
├─ Forest (Level 15)
├─ Mountains (Level 20)
└─ Space (Level 25)
```

---

## 📱 UI SCREENS

### Kids Dashboard (Watch)

```
┌─────────────────────────────────────────┐
│                                         │
│        SPARKY (Level 5)                 │
│     [Blue Buddy with Cap]               │
│      [Bouncing animation]               │
│                                         │
│  💚💚💚💚🖤  Happy: 80%              │
│  ⚡⚡⚡🖤🖤  Energy: 60%             │
│                                         │
│  ┌─────────────┐ ┌─────────────┐      │
│  │  🏃 MOVE!   │ │  🎨 DRESS   │      │
│  │             │ │   UP        │      │
│  └─────────────┘ └─────────────┘      │
│                                         │
│  Today: ⭐⭐⭐ (30 min)             │
└─────────────────────────────────────────┘
```

### Color Selection Screen

```
┌─────────────────────────────────────────┐
│ ← Back      Change Buddy's Color       │
├─────────────────────────────────────────┤
│                                         │
│     [Large Buddy Preview]               │
│      Currently: BLUE                    │
│                                         │
│  AVAILABLE:                             │
│  ┌───┐ ┌───┐ ┌───┐                    │
│  │✓🔵│ │ 🐚│ │ 🟢│ ← Unlocked         │
│  │Blue│ │Teal│ │Green                  │
│  └───┘ └───┘ └───┘                    │
│                                         │
│  UNLOCK SOON: (Keep going!)             │
│  ┌───┐ ┌───┐ ┌───┐                    │
│  │🔒│ │🔒│ │🔒│                    │
│  │🟣│ │🟡│ │🟠│                    │
│  │Purple Pink│Orange                    │
│  └───┘ └───┘ └───┘                    │
│  Lvl 8  Lvl 20 Lvl 15                  │
│                                         │
│  [TAP COLOR TO CHANGE]                  │
└─────────────────────────────────────────┘
```

### Dress Up Screen

```
┌─────────────────────────────────────────┐
│ ← Back      Dress Up Buddy             │
├─────────────────────────────────────────┤
│                                         │
│     [Interactive Buddy]                 │
│     [Tap to try accessories]            │
│                                         │
│ HATS:                                   │
│ ┌─────┐ ┌─────┐ ┌─────┐               │
│ │  🧢 │ │ 🔒  │ │ 🔒  │               │
│ │ Cap │ │Crown│ │Mask │               │
│ └─────┘ └─────┘ └─────┘               │
│   ✓       Lvl15   Lvl20                │
│                                         │
│ CLOTHES:                                │
│ ┌─────┐ ┌─────┐ ┌─────┐               │
│ │  👕 │ │  🔒 │ │  🔒 │               │
│ │Basic│ │Jersey│ │Cape │               │
│ └─────┘ └─────┘ └─────┘               │
│   ✓       Lvl5    Lvl20                │
│                                         │
│ [SAVE OUTFIT]                           │
└─────────────────────────────────────────┘
```

---

## 🗄️ DATABASE SCHEMA

```sql
-- Single pet with color customization
CREATE TABLE pets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID REFERENCES children(id) UNIQUE, -- One pet per child
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT 'blue', -- Current selected color
  level INT DEFAULT 1,
  xp INT DEFAULT 0,
  happiness INT DEFAULT 50,
  health INT DEFAULT 50,

  -- Unlocked content
  unlocked_colors TEXT[] DEFAULT ARRAY['blue'], -- Start with only blue
  unlocked_accessories JSONB DEFAULT '{"hats": [], "clothes": [], "shoes": [], "extras": []}',

  -- Current outfit
  current_accessories JSONB DEFAULT '{"hat": null, "clothes": "basic", "shoes": null, "extra": null}',
  current_background TEXT DEFAULT 'home',

  -- Stage progression
  stage TEXT DEFAULT 'baby', -- baby, kid, teen, super, mega

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Color unlock log
CREATE TABLE color_unlocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID REFERENCES pets(id),
  color TEXT NOT NULL,
  unlocked_at TIMESTAMP DEFAULT NOW(),
  unlock_reason TEXT -- 'level_up', 'streak', 'special_event'
);

-- Accessory unlock log
CREATE TABLE accessory_unlocks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID REFERENCES pets(id),
  accessory_type TEXT NOT NULL, -- 'hat', 'clothes', 'shoes', 'extra'
  accessory_name TEXT NOT NULL,
  unlocked_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🎨 BUDDY RENDERING SYSTEM

### Color Application

```dart
class BuddyRenderer {
  // Main body color (user-selected)
  Color primaryColor;

  // Auto-generated accent colors
  Color lighterShade;      // Belly, inner ears
  Color darkerShade;       // Outline, shadows

  // Fixed colors
  Color eyeWhite = Colors.white;
  Color eyePupil = Colors.black;
  Color mouth = Color(0xFF333333);

  // Accessories keep original colors
  Color capRed = Color(0xFFFF6B6B);
  Color capeBlue = Color(0xFF4ECDC4);
}
```

---

## 🎯 GAMIFICATION SYSTEM

### Character Traits

```
Shape: Rounded, soft, friendly
Style: Simple geometric shapes (easy to animate)
Features:
  - Large expressive eyes
  - Small arms and legs
  - Round body (like a bean or blob)
  - Optional tail (small, curved)
  - Smooth edges (no sharp corners)
```

### Animation States

```dart
enum BuddyAnimation {
  idle,           // Gentle breathing, blinking
  happy,          // Jumping, smiling
  excited,        // Spinning, bouncing
  exercising,     // Running in place, jumping jacks
  tired,          // Slow movement, yawning
  sleeping,       // Eyes closed, "Z" particles
  celebrating,    // Confetti, stars, victory pose
  thinking,       // Question mark bubble
  encouraging,    // Thumbs up, motivational bounce
}
```

### Color Application

```dart
class BuddyRenderer {
  // Main body color
  Color primaryColor;      // User's selected color

  // Accent colors (auto-generated from primary)
  Color lighterShade;      // Belly, inner ears
  Color darkerShade;       // Outline, shadows

  // Fixed colors
  Color eyeWhite = Colors.white;
  Color eyePupil = Colors.black;
  Color mouth = Color(0xFF333333);

  // Accessories keep their original colors
  Color capRed = Color(0xFFFF6B6B);
  Color capeBlue = Color(0xFF4ECDC4);
}
```

---

## 🎯 SIMPLIFIED GAMIFICATION

### XP and Leveling

```dart
class PetLeveling {
  // Simplified XP curve for kids
  static int xpForLevel(int level) {
    return level * 100; // Level 1→2: 100 XP, Level 2→3: 200 XP
  }

  // Ways to earn XP
  static const xpRewards = {
    'complete_workout': 50,
    'meet_daily_goal': 30,
    'morning_exercise': 20,
    'good_sleep': 25,
    'healthy_meal_log': 15,
    'daily_login': 10,
    '7_day_streak': 100,
  };
}
```

### Progress Visualization

```
┌─────────────────────────────────────────┐
│ Next Color: 🐚 TEAL                    │
│                                         │
│ ████████░░░░░░░░  Level 3 (85%)        │
│                                         │
│ Keep going! Just 15 XP more!           │
│                                         │
│ Coming up: 🟢 Green (Level 5)          │
└─────────────────────────────────────────┘
```

---

## 🎉 UNLOCK CELEBRATION

```
┌─────────────────────────────────────────┐
│                                         │
│        ✨ LEVEL UP! ✨                 │
│           Level 3!                      │
│                                         │
│     [Buddy dancing animation]           │
│                                         │
│   🎉 NEW COLOR UNLOCKED! 🎉            │
│                                         │
│    ┌─────────────────────┐             │
│    │    🐚 TEAL          │             │
│    │                     │             │
│    │  [Preview Buddy     │             │
│    │   in calm teal]     │             │
│    └─────────────────────┘             │
│                                         │
│  Next unlock: 🟢 Green at Level 5!     │
│                                         │
│  ┌───────────────────────────┐         │
│  │   [TRY IT NOW!]           │         │
│  └───────────────────────────┘         │
│                                         │
│  ┌───────────────────────────┐         │
│  │   [KEEP BLUE]             │         │
│  └───────────────────────────┘         │
└─────────────────────────────────────────┘
```

---

## 🚀 IMPLEMENTATION PHASES

### Phase 1: Buddy Foundation (Week 1)

- [ ] Design Buddy character (5 stages)
- [ ] Create 8 color variants (blue-centered palette)
- [ ] Build color selection UI
- [ ] Implement Buddy widget with color system
- [ ] Basic animations (idle, happy, tired)

### Phase 2: Onboarding (Week 2)

- [ ] Color picker screen
- [ ] Buddy naming screen
- [ ] Quick profile setup
- [ ] First mission tutorial
- [ ] Onboarding completion celebration

### Phase 3: Customization (Week 3)

- [ ] Dress-up screen UI
- [ ] Accessory system (5-10 items)
- [ ] Background system (5 environments)
- [ ] Unlock progression logic
- [ ] Preview before unlock

### Phase 4: Progression (Week 4)

- [ ] XP system
- [ ] Level-up animations
- [ ] Color unlock notifications
- [ ] Stage evolution (baby→kid→teen→super)
- [ ] Milestone celebrations

### Phase 5: Parent Features (Week 5-6)

- [ ] Parent dashboard
- [ ] Activity monitoring
- [ ] Privacy controls
- [ ] Weekly/monthly reports
- [ ] Settings management

### Phase 6: Polish (Week 7)

- [ ] Smooth all animations
- [ ] Sound effects (optional)
- [ ] Easter eggs (rare colors)
- [ ] Performance optimization
- [ ] Accessibility features

---

## 📂 PROJECT STRUCTURE

```
lib/
├── main.dart                 # Phone app entry
├── main_wear.dart           # Watch app entry
├── features/
│   └── buddy/
│       ├── domain/
│       │   ├── buddy_usecases.dart
│       │   └── buddy_repository.dart (interface)
│       ├── data/
│       │   ├── buddy_supabase_repository.dart
│       │   └── color_unlock_service.dart
│       ├── platform/
│       │   └── buddy_animation_controller.dart
│       └── presentation/
│           ├── onboarding/
│           │   ├── buddy_color_selection.dart
│           │   ├── buddy_naming.dart
│           │   └── quick_profile.dart
│           ├── home/
│           │   └── kids_dashboard.dart
│           └── customization/
│               ├── color_picker_screen.dart
│               ├── dress_up_screen.dart
│               └── unlock_preview.dart
├── models/
│   ├── buddy.dart
│   ├── buddy_customization.dart
│   └── buddy_animation.dart
├── services/
│   ├── supabase_service.dart
│   ├── watch_bridge.dart
│   └── phone_data_listener.dart
├── widgets/
│   ├── buddy_widget.dart
│   ├── color_swatch_button.dart
│   ├── locked_item_widget.dart
│   └── unlock_celebration.dart
└── utils/
    └── constants.dart

assets/
├── buddy/
│   ├── animations/
│   │   ├── idle.json (Lottie)
│   │   ├── happy.json
│   │   ├── exercise.json
│   │   └── celebrate.json
│   └── accessories/
│       ├── cap.svg
│       ├── cape.svg
│       └── crown.svg
└── backgrounds/
    ├── home.svg
    └── park.svg

test/
└── features/
    └── buddy/
        ├── domain/
        ├── data/
        └── platform/
```

---

## 🛠️ DEVELOPMENT GUIDELINES

### UI/UX Standards (Kid-Friendly)

1. **Touch Targets**: Minimum 48x48 logical pixels for buttons
2. **Typography**: Large, readable fonts (minimum 16sp body text)
3. **Colors**: Bright, cheerful colors from `BuddyColors`
4. **Icons**: Simple, recognizable with text labels
5. **Animations**: Smooth transitions (200-300ms duration)
6. **Feedback**: Immediate visual response to taps
7. **Language**: Simple, encouraging, age-appropriate (7-12)
8. **Error Messages**: Friendly, non-technical ("Oops! Let's try again!")

### Code Standards

```dart
// Example: Feature-first clean architecture
class StartHeartRateUseCase {
  final HeartRateRepository repository;

  StartHeartRateUseCase(this.repository);

  Future<void> execute() async {
    await repository.startTracking();
  }
}

// Implementation in platform layer
class WatchHeartRateRepository implements HeartRateRepository {
  final WatchBridgeService _bridge;

  @override
  Future<void> startTracking() async {
    await _bridge.startHeartRate();
  }
}
```

### Testing Requirements

- **Unit Tests**: Domain logic and use cases
- **Widget Tests**: UI components and screens
- **Integration Tests**: Platform channel mocking (see `test/services/watch_bridge_test.dart`)

```dart
// Example: Method channel test
testWidgets('Color selection updates Buddy preview', (tester) async {
  TestDefaultBinaryMessengerBinding.instance
    .defaultBinaryMessenger
    .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'updateColor') {
        return {'success': true};
      }
    });

  // Test color selection logic
});
```

---

## 📊 SUCCESS METRICS

### Kid Engagement

- **Color unlock rate**: 80% unlock first 3 colors (blue, teal, green)
- **Customization usage**: 50% try new color when unlocked
- **Color satisfaction**: 90% happy with available colors
- **Stage progression**: Average level 10 within 4 weeks
- **Daily active users**: 70% return rate

### Parent Satisfaction

- **Setup simplicity**: 90% complete setup in <2 minutes
- **Understanding**: 85% understand color reward system
- **Safety approval**: 95% feel app is safe
- **Monitoring**: 80% check dashboard weekly

---

## 🔐 PRIVACY & SAFETY

### COPPA Compliance

- Parental consent for account creation
- Minimal data collection (only fitness metrics)
- No personal information sharing
- Parent-controlled privacy settings
- Secure data storage in Supabase

### Content Safety

- Age-appropriate challenges and language
- No social features without parental approval
- Filtered leaderboards (friends only)
- Moderated community features (future)

---

## 📚 KEY DOCUMENTATION

- **Main Setup**: `README.md`
- **Quick Start**: `docs/QUICK_START.md`
- **Wear OS Setup**: `docs/WEAR_OS_SETUP.md`
- **Troubleshooting**: `docs/TROUBLESHOOTING.md`
- **AI Instructions**: `.github/copilot-instructions.md`

---

## ❓ IMPLEMENTATION DECISIONS

### 1. Buddy Character Style

**Decision**: Simple blob/bean shape

- ✅ Easy to animate
- ✅ Color-friendly (solid fills)
- ✅ Scalable across sizes
- ✅ Kid-appealing

### 2. Accessories Priority

**Decision**: Start with 5 essential items

- Cap, Jersey, Shoes, Backpack, Sunglasses
- Expand to 15+ items based on engagement

### 3. Color Palette Strategy

**Decision**: Blue-centered, gradually expanding palette

- Start with calming blue (reduces overwhelm)
- Unlock complementary colors first (teal, green)
- Expand to full spectrum gradually (purple, yellow, orange, pink, navy)
- Special effects optional for future (gradient, shimmer)

### 4. App Naming

**Decision**: "FlowFit Kids" with Buddy branding

- Main app: FlowFit Kids
- Mascot: Buddy the FlowFit Companion

---

## 🎯 WHY SINGLE PET SYSTEM?

**Advantages:**

- ✅ Easier to develop (one character, multiple customizations)
- ✅ Kid-friendly (one friend, many looks)
- ✅ Focused progression (unlock colors vs. unlock pets)
- ✅ Better brand identity (one memorable mascot)
- ✅ Scalable (seasonal colors, special effects)
- ✅ Lower cognitive load for target age (7-12)

**vs. Multiple Pets:**

- ❌ Choice paralysis for kids
- ❌ More complex progression
- ❌ Higher development cost
- ❌ Diluted brand identity

---

## 🚦 GETTING STARTED

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / Xcode
- Supabase account
- Galaxy Watch (for Wear OS testing)

### Installation

```bash
# Install dependencies
flutter pub get

# Run phone app
flutter run -d <phone-device-id> -t lib/main.dart

# Run watch app
flutter run -d <watch-device-id> -t lib/main_wear.dart

# Run tests
flutter test
```

### Configuration

1. Copy `lib/secrets.dart.example` to `lib/secrets.dart`
2. Add Supabase URL and anon key
3. Configure Samsung Health permissions in `AndroidManifest.xml`

---

**Ready to build Buddy! 🎨 Start with Phase 1: Buddy Foundation.**
