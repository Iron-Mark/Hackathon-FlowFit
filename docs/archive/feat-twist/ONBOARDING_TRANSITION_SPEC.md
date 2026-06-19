# ONBOARDING TRANSITION SPECIFICATION

**From Current Health Survey Flow → Buddy-Centered Kids Onboarding**

---

## 📊 CURRENT STATE ANALYSIS

### Existing Onboarding Flow

```
Current Flow (Adults/General Users):
┌────────────────────────────────────────┐
│ 1. OnboardingScreen                   │
│    - 3 feature slides                  │
│    - Heart rate, workouts, progress    │
│    - Skip option                       │
└────────────────────────────────────────┘
                 ↓
┌────────────────────────────────────────┐
│ 2. SurveyIntroScreen (Step 0/4)       │
│    - Welcome message                   │
│    - Feature preview cards             │
│    - "Let's Get Started" button        │
│    ❌ ADULT-FOCUSED, REPLACE WITH BUDDY │
└────────────────────────────────────────┘
                 ↓
            Dashboard

⚠️ REMOVED SCREENS (Adult-focused, not suitable for kids 7-12):

❌ SurveyBasicInfoScreen
   - Collects first name (PII - COPPA violation)
   - Age range 13-120 excludes target audience (7-12)
   - Gender binary not inclusive
   - No parental consent flow
re
❌ SurveyBodyMeasurementsScreen
   - Height/weight tracking inappropriate for kids
   - Can trigger body image issues
   - Kids don't need detailed metrics

❌ SurveyActivityGoalsScreen
   - Too complex for kids to self-assess
   - "Activity level" is abstract for age 7-12
   - Fitness goals better handled via Buddy gamification

❌ SurveyDailyTargetsScreen
   - Calorie counting harmful for children
   - Macro split (protein/carbs/fat) too technical
   - No nutritional expertise at this age
```

### Current Technical Stack

- **State Management**: Riverpod (`surveyNotifierProvider`)
- **Navigation**: Named routes (`/survey_intro`, `/survey_basic_info`, etc.)
- **Persistence**: Supabase (profile table)
- **Validation**: Form validators in each screen
- **Widgets**: Reusable `SurveyAppBar`, `SurveyProgressIndicator`
- **Target Audience**: Adults (13-120 years old) ❌ NOT KIDS 7-12
- **Data Focus**: Body metrics, calories, macros ❌ HARMFUL FOR KIDS

### ⚠️ Current Flow Problems for Kids:

1. **Body Measurements** - Can trigger body image issues, not developmentally appropriate
2. **Calorie/Macro Tracking** - Too technical, potentially harmful for children
3. **Activity Goals** - Abstract concepts kids can't self-assess
4. **Age Range** - 13-120 excludes primary target (7-12)
5. **Gender Binary** - Not inclusive, unnecessary data collection
6. **No Parental Oversight** - COPPA compliance requires parent involvement
7. **No Gamification** - No motivation for kids to engage
8. **Text-Heavy** - Not engaging for young users

---

## 🎯 TARGET STATE (BUDDY ONBOARDING)

### New Buddy-Centered Flow (Kids 7-12) - Whale-Themed

```
New Flow (8 screens - conversational & engaging):
┌────────────────────────────────────────┐
│ 1. BuddyWelcomeScreen                 │
│    "Meet Your Fitness Buddy!"          │
│    [Animated Buddy bouncing]           │
│    Duration: 5 seconds                 │
│    [LET'S GO!] button                  │
│    Skip: Top-right corner              │
└────────────────────────────────────────┘
                 ↓
┌────────────────────────────────────────┐
│ 2. BuddyIntroScreen                   │
│    Speech bubble from Buddy:           │
│    "Splash splash, thanks for finding  │
│     me. If my name is Bubbles, what's  │
│     your name?"                        │
│    Input: "Name for Bubbles' human..." │
│    [Large Buddy in Ocean Blue]         │
│    [NEXT] button (disabled until input)│
└────────────────────────────────────────┘
                 ↓
┌────────────────────────────────────────┐
│ 3. BuddyHatchScreen                   │
│    "You found a baby whale!"           │
│    [Buddy emergence animation]         │
│    Auto-advance after 2 seconds        │
└────────────────────────────────────────┘
                 ↓
┌────────────────────────────────────────┐
│ 4. BuddyEggSelectionScreen            │
│    "Choose your Whale Color!"          │
│    Subtitle: "Whales are gentle,       │
│     playful, and smart..."             │
│    [6 egg colors in circle pattern]    │
│    - Blue (top center)                 │
│    - Gray, Orange (sides)              │
│    - Purple, Pink (bottom sides)       │
│    - Green (bottom center)             │
│    [Buddy in center watching]          │
│    [Hatch egg] button                  │
└────────────────────────────────────────┘
                 ↓
┌────────────────────────────────────────┐
│ 5. BuddyNamingScreen                  │
│    [Hatched Buddy with personality]    │
│    "What do you want to name your      │
│     baby whale?"                       │
│    "You can change this later."        │
│    Input field with current name       │
│    [Shuffle] button - randomize name   │
│    [Next] button (large, green)        │
└────────────────────────────────────────┘
                 ↓
┌────────────────────────────────────────┐
│ 6. GoalSelectionScreen                │
│    Progress: ●●●○ (step indicator)     │
│    [Buddy with lightbulb icon]         │
│    "What areas would you like          │
│     support with?"                     │
│    Multi-select cards:                 │
│    ✓ Boost focus and productivity      │
│    ✓ Stay fresh and clean              │
│    ○ Be more active                    │
│    ○ Manage stress and anxiety         │
│    ○ Strengthen social skills          │
│    [Next] button                       │
└────────────────────────────────────────┘
                 ↓
┌────────────────────────────────────────┐
│ 7. NotificationPermissionScreen       │
│    "Get reminders from {BuddyName}"    │
│    Preview notification card:          │
│    "From Bubbles • now"                │
│    "Remember to drink water!"          │
│    [Buddy animation - thinking]        │
│    [Turn on notifications] (green)     │
│    [Maybe later] (gray)                │
└────────────────────────────────────────┘
                 ↓
┌────────────────────────────────────────┐
│ 8. BuddyReadyScreen                   │
│    Speech bubble:                      │
│    "Wow! When you take care of         │
│     yourself, you take care of me      │
│     too! Let's swim together!"         │
│    [Buddy holding heart ❤️]            │
│    Stats gain notification:            │
│    "😍 Bubbles gained +5.9 Compassion" │
│    [Next] button → Dashboard           │
└────────────────────────────────────────┘
```

### Target Requirements

- **Duration**: 90 seconds maximum
- **Age Range**: 7-12 years old (vs current 13-120)
- **Language**: Simple, encouraging, kid-friendly
- **Touch Targets**: Minimum 48x48 logical pixels
- **Animations**: Smooth, delightful (200-300ms)
- **Skip Options**: Limited (only on Step 4)
- **Data Collection**: MINIMAL (COPPA compliant)
- **Visual Style**: Bright, colorful, playful

---

## 🔄 TRANSITION STRATEGY

### Option 1: FULL REPLACEMENT (Recommended)

**Replace adult onboarding entirely with kids flow**

**Pros:**

- ✅ Cleaner codebase
- ✅ Focused on target audience (kids 7-12)
- ✅ Simpler data model
- ✅ Better UX alignment

**Cons:**

- ❌ Loses adult user support
- ❌ More initial development work

**Decision:** Use this if FlowFit Kids is the sole product.

---

### Option 2: DUAL FLOW (Age-Based Routing)

**Keep both flows, route based on age detection**

```dart
// Pseudo-code routing logic
if (userAge >= 13) {
  Navigator.pushNamed(context, '/survey_intro'); // Adult flow
} else if (userAge >= 7 && userAge <= 12) {
  Navigator.pushNamed(context, '/buddy_welcome'); // Kids flow
} else {
  // Show age error or parent verification
}
```

**Pros:**

- ✅ Supports both audiences
- ✅ Gradual migration
- ✅ A/B testing possible

**Cons:**

- ❌ Maintains two codebases
- ❌ More complex routing
- ❌ Larger bundle size

**Decision:** Use this if FlowFit supports multiple age groups.

---

### Option 3: HYBRID (Feature Flags)

**Use feature flags to toggle between flows**

```dart
// Using environment or remote config
final bool useBuddyOnboarding =
    RemoteConfig.instance.getBool('enable_buddy_onboarding');

if (useBuddyOnboarding) {
  Navigator.pushNamed(context, '/buddy_welcome');
} else {
  Navigator.pushNamed(context, '/survey_intro');
}
```

**Pros:**

- ✅ Easy rollback
- ✅ Gradual rollout
- ✅ A/B testing built-in

**Cons:**

- ❌ Both flows always in bundle
- ❌ Requires remote config setup

---

## 📝 IMPLEMENTATION PLAN

### Phase 1: Feature Module Setup (Week 1)

#### 1.1 Create Buddy Feature Module

**Directory**: `lib/features/buddy/`

**Domain Layer** (`domain/models/`):

```dart
// lib/features/buddy/domain/models/buddy.dart
class Buddy {
  final String id;
  final String name;           // User-given name (e.g., "Cookie")
  final String color;          // Current color (default: 'blue')
  final int level;             // Current level
  final int xp;                // Experience points
  final BuddyStats stats;      // Happiness, compassion, etc.
  final String stage;          // 'baby', 'kid', 'teen', 'super'
  final List<String> unlockedColors;
  final DateTime createdAt;

  const Buddy({
    required this.id,
    required this.name,
    this.color = 'blue',
    this.level = 1,
    this.xp = 0,
    required this.stats,
    this.stage = 'baby',
    this.unlockedColors = const ['blue'],
    required this.createdAt,
  });
}

// lib/features/buddy/domain/models/buddy_stats.dart
class BuddyStats {
  final double happiness;      // 0-100
  final double compassion;     // Whale companion - stat gain
  final double focus;          // Based on user goals
  final double energy;         // Activity-based

  const BuddyStats({
    this.happiness = 50.0,
    this.compassion = 0.0,
    this.focus = 0.0,
    this.energy = 50.0,
  });

  BuddyStats gainCompassion(double amount) {
    return BuddyStats(
      happiness: happiness,
      compassion: compassion + amount,
      focus: focus,
      energy: energy,
    );
  }
}
```

**Domain Layer** (`domain/repositories/`):

```dart
// lib/features/buddy/domain/repositories/buddy_repository.dart
abstract class BuddyRepository {
  Future<Buddy> createBuddy(String childId, String name, String color);
  Future<Buddy?> getBuddyByChildId(String childId);
  Future<Buddy> updateBuddyName(String buddyId, String name);
  Future<Buddy> unlockColor(String buddyId, String color);
  Future<Buddy> levelUp(String buddyId);
  Future<Buddy> updateStats(String buddyId, BuddyStats stats);
}
```

**Domain Layer** (`domain/usecases/`):

```dart
// lib/features/buddy/domain/usecases/create_buddy_usecase.dart
class CreateBuddyUseCase {
  final BuddyRepository repository;

  CreateBuddyUseCase(this.repository);

  Future<Buddy> execute({
    required String childId,
    required String name,
    String color = 'blue',
  }) async {
    // Validate name
    if (name.length < 2 || name.length > 15) {
      throw ArgumentError('Name must be 2-15 characters');
    }

    return await repository.createBuddy(childId, name, color);
  }
}
```

#### 1.2 Create Onboarding Feature Module

**Directory**: `lib/features/onboarding/`

**Domain Layer** (`domain/models/`):

```dart
// lib/features/onboarding/domain/models/onboarding_state.dart
class OnboardingState {
  final int currentStep;       // 0-7
  final String? userName;      // User's name (entered in step 2)
  final String? buddyName;     // Buddy's name (step 5)
  final String? selectedEggColor; // Egg color choice (step 4)
  final List<String> selectedGoals; // Goals from step 6
  final bool notificationsGranted;

  const OnboardingState({
    this.currentStep = 0,
    this.userName,
    this.buddyName,
    this.selectedEggColor,
    this.selectedGoals = const [],
    this.notificationsGranted = false,
  });

  OnboardingState copyWith({
    int? currentStep,
    String? userName,
    String? buddyName,
    String? selectedEggColor,
    List<String>? selectedGoals,
    bool? notificationsGranted,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      userName: userName ?? this.userName,
      buddyName: buddyName ?? this.buddyName,
      selectedEggColor: selectedEggColor ?? this.selectedEggColor,
      selectedGoals: selectedGoals ?? this.selectedGoals,
      notificationsGranted: notificationsGranted ?? this.notificationsGranted,
    );
  }

  bool get isComplete => currentStep >= 7;
  double get progress => (currentStep + 1) / 8; // 8 total steps
}
```

#### 1.3 Create Goals Feature Module (NEW - whale companion)

**Directory**: `lib/features/goals/`

```dart
// lib/features/goals/domain/models/wellness_goal.dart
class WellnessGoal {
  final String id;
  final String title;
  final String icon;           // Emoji or icon name
  final GoalCategory category;
  final bool isSelected;

  const WellnessGoal({
    required this.id,
    required this.title,
    required this.icon,
    required this.category,
    this.isSelected = false,
  });

  static const predefinedGoals = [
    WellnessGoal(
      id: 'focus',
      title: 'Boost focus and productivity',
      icon: '🎯',
      category: GoalCategory.productivity,
    ),
    WellnessGoal(
      id: 'hygiene',
      title: 'Stay fresh and clean',
      icon: '🪥',
      category: GoalCategory.selfCare,
    ),
    WellnessGoal(
      id: 'active',
      title: 'Be more active',
      icon: '👟',
      category: GoalCategory.fitness,
    ),
    WellnessGoal(
      id: 'stress',
      title: 'Manage stress and anxiety',
      icon: '🏔️',
      category: GoalCategory.mentalHealth,
    ),
    WellnessGoal(
      id: 'social',
      title: 'Strengthen social skills and connections',
      icon: '☎️',
      category: GoalCategory.social,
    ),
  ];
}

enum GoalCategory {
  productivity,
  selfCare,
  fitness,
  mentalHealth,
  social,
}
```

#### 1.2 Create Database Schema

```sql
-- Add to supabase/migrations/
CREATE TABLE buddies (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  child_id UUID REFERENCES children(id) UNIQUE,
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT 'blue',
  level INT DEFAULT 1,
  xp INT DEFAULT 0,
  happiness INT DEFAULT 50 CHECK (happiness >= 0 AND happiness <= 100),
  health INT DEFAULT 50 CHECK (health >= 0 AND health <= 100),
  stage TEXT DEFAULT 'baby' CHECK (stage IN ('baby', 'kid', 'teen', 'super', 'mega')),
  unlocked_colors TEXT[] DEFAULT ARRAY['blue'],
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Index for quick lookups
CREATE INDEX idx_buddies_child_id ON buddies(child_id);

-- Update trigger
CREATE TRIGGER update_buddies_updated_at
  BEFORE UPDATE ON buddies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

#### 1.3 Create State Providers

```dart
// lib/presentation/providers/buddy_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/buddy.dart';
import '../../services/buddy_service.dart';

final buddyServiceProvider = Provider<BuddyService>((ref) {
  return BuddyService();
});

final buddyNotifierProvider =
    StateNotifierProvider<BuddyNotifier, AsyncValue<Buddy?>>((ref) {
  return BuddyNotifier(ref.watch(buddyServiceProvider));
});

class BuddyNotifier extends StateNotifier<AsyncValue<Buddy?>> {
  final BuddyService _service;

  BuddyNotifier(this._service) : super(const AsyncValue.loading());

  Future<void> createBuddy(String childId, String name) async {
    state = const AsyncValue.loading();
    try {
      final buddy = await _service.createBuddy(childId, name);
      state = AsyncValue.data(buddy);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadBuddy(String childId) async {
    state = const AsyncValue.loading();
    try {
      final buddy = await _service.getBuddyByChildId(childId);
      state = AsyncValue.data(buddy);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateBuddyName(String name) async {
    final currentBuddy = state.value;
    if (currentBuddy == null) return;

    try {
      final updated = await _service.updateBuddy(
        currentBuddy.id,
        name: name,
      );
      state = AsyncValue.data(updated);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
```

```dart
// lib/presentation/providers/onboarding_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingState {
  final String? buddyName;
  final String? kidNickname;
  final int? kidAge;
  final int currentStep;

  const OnboardingState({
    this.buddyName,
    this.kidNickname,
    this.kidAge,
    this.currentStep = 0,
  });

  OnboardingState copyWith({
    String? buddyName,
    String? kidNickname,
    int? kidAge,
    int? currentStep,
  }) {
    return OnboardingState(
      buddyName: buddyName ?? this.buddyName,
      kidNickname: kidNickname ?? this.kidNickname,
      kidAge: kidAge ?? this.kidAge,
      currentStep: currentStep ?? this.currentStep,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(const OnboardingState());

  void setBuddyName(String name) {
    state = state.copyWith(buddyName: name);
  }

  void setKidInfo(String? nickname, int age) {
    state = state.copyWith(kidNickname: nickname, kidAge: age);
  }

  void nextStep() {
    state = state.copyWith(currentStep: state.currentStep + 1);
  }

  void reset() {
    state = const OnboardingState();
  }
}

final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});
```

---

### Phase 2: Screen Implementation (Week 2)

#### 2.1 Screen 1: BuddyWelcomeScreen

**File**: `lib/features/onboarding/presentation/screens/01_buddy_welcome_screen.dart`

**Purpose**: First impression - animated Buddy introduction

**Key Elements** (whale companion theme):

- Fullscreen Buddy animation (bouncing/floating)
- Large "Meet Your Fitness Buddy!" text
- Clean white background
- Skip button (top-right)
- Single "LET'S GO!" button (large, green)

---

#### 2.2 Screen 2: BuddyIntroScreen

**File**: `lib/features/onboarding/presentation/screens/02_buddy_intro_screen.dart`

**Purpose**: Conversational introduction - Buddy asks for user's name

**Key Elements** (whale companion pattern):

- Speech bubble from Buddy at top
  - "Splash splash, thanks for finding me."
  - "If my name is Bubbles, what's your name?"
- Buddy character centered
- Large text input field at bottom
  - Placeholder: "Name for Cookie's human..."
  - Auto-focus on mount
- Skip button (top-right)
- Next button (disabled until input)

**Interaction**:

```dart
// Feature-specific widget
class NameInputField extends StatefulWidget {
  final Function(String) onNameChanged;
  final String buddyName;

  @override
  Widget build(BuildContext context) {
    return TextField(
      autofocus: true,
      style: TextStyle(fontSize: 20),
      decoration: InputDecoration(
        hintText: 'Name for $buddyName\'s friend...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      onChanged: onNameChanged,
    );
  }
}
```

---

#### 2.3 Screen 3: BuddyHatchScreen

**File**: `lib/features/onboarding/presentation/screens/03_buddy_hatch_screen.dart`

**Purpose**: Delightful micro-interaction - "You found a baby whale!"

**Key Elements**:

- Buddy centered
- Text: "You found a baby whale!"
- Auto-advance after 2 seconds
- Optional: Confetti/particle animation

---

#### 2.4 Screen 4: BuddyEggSelectionScreen

**File**: `lib/features/onboarding/presentation/screens/04_buddy_egg_selection_screen.dart`

**Purpose**: Choose Buddy's starting color via egg selection

**Key Elements** (whale companion):

- Title: "Choose your Whale Color!"
- Subtitle explaining personality
- 6 eggs in circular pattern around Buddy
  - Top: Blue
  - Mid-left: Gray, Mid-right: Orange
  - Bottom-left: Purple, Bottom-right: Pink
  - Bottom: Green
- Buddy character in center (watching/reacting)
- Selected egg has visual feedback
- "Hatch egg" button (large, green)

**Widget Structure**:

```dart
// lib/features/onboarding/presentation/widgets/egg_selector.dart
class EggSelector extends StatefulWidget {
  final Function(String) onEggSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Buddy in center
        Center(child: BuddyAvatar(stage: 'baby')),

        // Eggs in circular layout
        Positioned(
          top: 100,
          child: EggButton(color: 'blue', onTap: () => onEggSelected('blue')),
        ),
        // ... other eggs
      ],
    );
  }
}
```

---

#### 2.5 Screen 5: BuddyNamingScreen

**File**: `lib/features/onboarding/presentation/screens/05_buddy_naming_screen.dart`

**Purpose**: Name the Buddy (editable, with shuffle option)

**Key Elements** (whale companion pattern):

- Hatched Buddy with selected color
- Title: "What do you want to name your baby whale?"
- Subtitle: "You can change this later."
- Text field with current name (pre-filled with suggestion)
- "Shuffle" button - randomize from name list
- "Next" button (large, green)
- Back button (top-left)

**Name Suggestions**:

```dart
// lib/features/buddy/domain/models/buddy_name_generator.dart
class BuddyNameGenerator {
  static const names = [
    'Bubbles', 'Splash', 'Wave', 'Marina', 'Ocean',
    'Finn', 'Luna', 'Neptune', 'Coral', 'Pearl',
    'Moby', 'Tide', 'Azure', 'Blue', 'Aqua',
  ];

  static String random() {
    return names[Random().nextInt(names.length)];
  }
}
```

---

#### 2.6 Screen 6: GoalSelectionScreen (NEW - whale companion)

**File**: `lib/features/onboarding/presentation/screens/06_goal_selection_screen.dart`

**Purpose**: Select wellness goals (multi-select)

**Key Elements**:

- Progress indicator: ●●●○ (step 3 of 4)
- Buddy with lightbulb icon (thinking pose)
- Title: "What areas would you like support with?"
- Multi-select goal cards (from Goals feature)
- Green checkmark for selected
- Gray plus icon for unselected
- "Next" button (always enabled)

**Widget**:

```dart
// lib/features/goals/presentation/widgets/goal_card.dart
class GoalCard extends StatelessWidget {
  final WellnessGoal goal;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? Color(0xFF66BB6A) : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(goal.icon, style: TextStyle(fontSize: 32)),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                goal.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.add_circle_outline,
              color: isSelected ? Color(0xFF66BB6A) : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

#### 2.7 Screen 7: NotificationPermissionScreen

**File**: `lib/features/onboarding/presentation/screens/07_notification_permission_screen.dart`

**Purpose**: Request notification permission (optional)

**Key Elements** (Finch pattern):

- Title: "Get reminders from {BuddyName}"
- Preview notification card showing example
  - "From Cookie • now"
  - "Remember to drink water!"
- Buddy animation (thinking/encouraging)
- "Turn on notifications" button (green)
- "Maybe later" button (gray, secondary)

---

#### 2.8 Screen 8: BuddyReadyScreen

**File**: `lib/features/onboarding/presentation/screens/08_buddy_ready_screen.dart`

**Purpose**: Celebration & first stat gain

**Key Elements** (Finch pattern):

- Speech bubble:
  - "Wow! When you take care of yourself,"
  - "you take care of me, too!"
  - "Let's do it together, cheep!"
- Buddy holding heart emoji ❤️
- Stat gain notification (blue card):
  - "😍 Cookie gained +5.9 Compassion"
- "Next" button → Dashboard

**Implementation**:

```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class BuddyWelcomeScreen extends StatefulWidget {
  const BuddyWelcomeScreen({super.key});

  @override
  State<BuddyWelcomeScreen> createState() => _BuddyWelcomeScreenState();
}

class _BuddyWelcomeScreenState extends State<BuddyWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: -20, end: 20).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF), // Alice Blue
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Buddy
              AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: child,
                  );
                },
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4ECDC4), // Ocean Blue
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4ECDC4).withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '👋',
                      style: TextStyle(fontSize: 80),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              const Text(
                'Meet Your\nFitness Buddy!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              const Text(
                'Your new friend will help you\nstay active and have fun!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF7F8C8D),
                  height: 1.4,
                ),
              ),

              const Spacer(),

              // Let's Go Button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/buddy_intro');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0xFF4ECDC4).withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: const Text(
                    'LET\'S GO!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Routes to add**:

```dart
// lib/main.dart or routes file
'/buddy_welcome': (context) => const BuddyWelcomeScreen(),
```

---

#### 2.2 Screen 2: BuddyIntroScreen

**File**: `lib/screens/onboarding/buddy_intro_screen.dart`

**Purpose**: Show Buddy in blue, explain color unlock system

**Key Elements**:

- Large Buddy widget in ocean blue
- Speech bubble: "Hi! I'm your fitness buddy!"
- Color roadmap preview (Teal → Green → Purple)
- "LET'S GO!" button

---

#### 2.3 Screen 3: BuddyNamingScreen

**File**: `lib/screens/onboarding/buddy_naming_screen.dart`

**Purpose**: Let kid name their Buddy

**Key Elements**:

- Large text input (minimum 20sp font)
- Buddy reacts to typing (animation)
- Name suggestions (Sparky, Flash, Star, Rocket, Blaze)
- Validation: 2-15 characters, alphanumeric + spaces
- "THAT'S PERFECT!" button

**State Management**:

```dart
// Uses onboardingNotifierProvider
ref.read(onboardingNotifierProvider.notifier).setBuddyName(name);
```

---

#### 2.4 Screen 4: KidProfileScreen

**File**: `lib/screens/onboarding/kid_profile_screen.dart`

**Purpose**: Collect minimal kid info (COPPA compliant)

**Key Elements**:

- Optional nickname field
- Age selector (7-12 only) - large tap targets
- Skip option (goes straight to dashboard)
- Continue button (saves to Supabase)

**Validation**:

```dart
bool _validateAge(int age) {
  return age >= 7 && age <= 12;
}
```

---

#### 2.5 Screen 5: BuddyReadyScreen

**File**: `lib/screens/onboarding/buddy_ready_screen.dart`

**Purpose**: Celebration screen - Buddy is ready!

**Key Elements**:

- Buddy jumping/celebrating animation
- Confetti or particle effects
- Message: "{BuddyName} wants to play!"
- "START FIRST MISSION" button → Dashboard

---

### Phase 3: Service Layer (Week 3)

#### 3.1 Create BuddyService

**File**: `lib/services/buddy_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/buddy.dart';
import '../core/utils/logger.dart';

class BuddyService {
  final _supabase = Supabase.instance.client;
  final _logger = Logger('BuddyService');

  /// Create a new Buddy for a child
  Future<Buddy> createBuddy(String childId, String name) async {
    try {
      final response = await _supabase
          .from('buddies')
          .insert({
            'child_id': childId,
            'name': name,
            'color': 'blue',
            'level': 1,
            'xp': 0,
            'happiness': 50,
            'health': 50,
            'stage': 'baby',
            'unlocked_colors': ['blue'],
          })
          .select()
          .single();

      return Buddy.fromJson(response);
    } catch (e) {
      _logger.error('Failed to create buddy', error: e);
      rethrow;
    }
  }

  /// Get Buddy by child ID
  Future<Buddy?> getBuddyByChildId(String childId) async {
    try {
      final response = await _supabase
          .from('buddies')
          .select()
          .eq('child_id', childId)
          .maybeSingle();

      if (response == null) return null;
      return Buddy.fromJson(response);
    } catch (e) {
      _logger.error('Failed to get buddy', error: e);
      rethrow;
    }
  }

  /// Update Buddy name
  Future<Buddy> updateBuddy(String buddyId, {String? name}) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;

      final response = await _supabase
          .from('buddies')
          .update(updateData)
          .eq('id', buddyId)
          .select()
          .single();

      return Buddy.fromJson(response);
    } catch (e) {
      _logger.error('Failed to update buddy', error: e);
      rethrow;
    }
  }
}
```

---

### Phase 4: Navigation & Integration (Week 4)

#### 4.1 Update Route Configuration

**Current routes to modify**:

```dart
// FROM (Old):
'/onboarding': (context) => const OnboardingScreen(),
'/survey_intro': (context) => const SurveyIntroScreen(),

// TO (New):
'/buddy_welcome': (context) => const BuddyWelcomeScreen(),
'/buddy_intro': (context) => const BuddyIntroScreen(),
'/buddy_naming': (context) => const BuddyNamingScreen(),
'/kid_profile': (context) => const KidProfileScreen(),
'/buddy_ready': (context) => const BuddyReadyScreen(),
```

#### 4.2 Update Auth Flow

**File**: `lib/screens/auth/signup_screen.dart`

```dart
// After successful signup, detect user type
if (userAge != null && userAge >= 7 && userAge <= 12) {
  // Kids flow
  Navigator.pushReplacementNamed(context, '/buddy_welcome');
} else if (userAge != null && userAge >= 13) {
  // Adult flow (existing)
  Navigator.pushReplacementNamed(context, '/survey_intro');
} else {
  // Unknown age - ask for verification
  Navigator.pushReplacementNamed(context, '/age_verification');
}
```

---

## 🧪 TESTING PLAN

### Unit Tests

```dart
// test/services/buddy_service_test.dart
void main() {
  group('BuddyService', () {
    test('creates buddy with default values', () async {
      final service = BuddyService();
      final buddy = await service.createBuddy('child-123', 'Sparky');

      expect(buddy.name, 'Sparky');
      expect(buddy.color, 'blue');
      expect(buddy.level, 1);
      expect(buddy.unlockedColors, ['blue']);
    });

    test('validates buddy name length', () {
      expect(() => validateBuddyName('A'), throwsException);
      expect(() => validateBuddyName('ValidName'), returnsNormally);
    });
  });
}
```

### Widget Tests

```dart
// test/screens/buddy_naming_screen_test.dart
void main() {
  testWidgets('shows name suggestions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BuddyNamingScreen()),
    );

    expect(find.text('Sparky'), findsOneWidget);
    expect(find.text('Flash'), findsOneWidget);
    expect(find.text('Star'), findsOneWidget);
  });

  testWidgets('validates name input', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BuddyNamingScreen()),
    );

    final textField = find.byType(TextField);
    await tester.enterText(textField, 'A'); // Too short
    await tester.tap(find.text('THAT\'S PERFECT!'));
    await tester.pump();

    expect(find.text('Name must be 2-15 characters'), findsOneWidget);
  });
}
```

### Integration Tests

```dart
// integration_test/onboarding_flow_test.dart
void main() {
  testWidgets('completes full onboarding flow', (tester) async {
    await tester.pumpWidget(const MyApp());

    // Step 1: Welcome
    expect(find.text('Meet Your Fitness Buddy!'), findsOneWidget);
    await tester.tap(find.text('LET\'S GO!'));
    await tester.pumpAndSettle();

    // Step 2: Intro
    expect(find.text('Hi! I\'m your fitness buddy!'), findsOneWidget);
    await tester.tap(find.text('LET\'S GO!'));
    await tester.pumpAndSettle();

    // Step 3: Naming
    await tester.enterText(find.byType(TextField), 'Sparky');
    await tester.tap(find.text('THAT\'S PERFECT!'));
    await tester.pumpAndSettle();

    // Step 4: Profile
    await tester.tap(find.text('9')); // Select age 9
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    // Step 5: Ready
    expect(find.text('Sparky wants to play!'), findsOneWidget);
    await tester.tap(find.text('START FIRST MISSION'));
    await tester.pumpAndSettle();

    // Should navigate to dashboard
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
```

---

## 📦 FEATURE-FIRST FILE STRUCTURE

### Overview: Modular Feature Architecture

Instead of monolithic structure, organize by **feature** with clear boundaries:

```
lib/
├── features/
│   ├── buddy/                              # FEATURE MODULE
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   ├── buddy.dart
│   │   │   │   ├── buddy_color.dart
│   │   │   │   └── buddy_stats.dart
│   │   │   ├── repositories/
│   │   │   │   └── buddy_repository.dart   # Interface
│   │   │   └── usecases/
│   │   │       ├── create_buddy_usecase.dart
│   │   │       ├── update_buddy_name_usecase.dart
│   │   │       ├── unlock_color_usecase.dart
│   │   │       └── level_up_buddy_usecase.dart
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── buddy_local_datasource.dart
│   │   │   │   └── buddy_remote_datasource.dart
│   │   │   ├── repositories/
│   │   │   │   └── buddy_repository_impl.dart
│   │   │   └── models/
│   │   │       └── buddy_dto.dart           # Data Transfer Object
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── buddy_provider.dart
│   │   │   ├── widgets/
│   │   │   │   ├── buddy_avatar.dart        # Reusable Buddy display
│   │   │   │   ├── buddy_animation_widget.dart
│   │   │   │   ├── buddy_stats_card.dart
│   │   │   │   └── buddy_speech_bubble.dart
│   │   │   └── screens/
│   │   │       └── buddy_profile_screen.dart
│   │   └── README.md                        # Feature documentation
│   │
│   ├── onboarding/                          # FEATURE MODULE
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── onboarding_state.dart
│   │   │   └── repositories/
│   │   │       └── onboarding_repository.dart
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── onboarding_repository_impl.dart
│   │   ├── presentation/
│   │   │   ├── providers/
│   │   │   │   └── onboarding_provider.dart
│   │   │   ├── widgets/
│   │   │   │   ├── onboarding_progress_bar.dart
│   │   │   │   ├── name_input_field.dart
│   │   │   │   ├── age_selector_grid.dart
│   │   │   │   ├── goal_selector_card.dart    # Multi-select cards
│   │   │   │   └── skip_button.dart
│   │   │   └── screens/
│   │   │       ├── 01_buddy_welcome_screen.dart
│   │   │       ├── 02_buddy_intro_screen.dart
│   │   │       ├── 03_buddy_naming_screen.dart
│   │   │       ├── 04_kid_profile_screen.dart
│   │   │       ├── 05_goal_selection_screen.dart  # NEW - from Finch
│   │   │       ├── 06_notification_permission_screen.dart # NEW
│   │   │       └── 07_buddy_ready_screen.dart
│   │   └── README.md
│   │
│   ├── profile/                             # FEATURE MODULE
│   │   ├── domain/
│   │   │   ├── models/
│   │   │   │   └── kid_profile.dart
│   │   │   └── usecases/
│   │   │       ├── create_profile_usecase.dart
│   │   │       └── update_profile_usecase.dart
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── profile_repository_impl.dart
│   │   └── presentation/
│   │       └── providers/
│   │           └── profile_provider.dart
│   │
│   └── goals/                               # FEATURE MODULE (NEW - from Finch)
│       ├── domain/
│       │   ├── models/
│       │   │   ├── wellness_goal.dart
│       │   │   └── goal_category.dart
│       │   └── repositories/
│       │       └── goals_repository.dart
│       ├── data/
│       │   └── repositories/
│       │       └── goals_repository_impl.dart
│       └── presentation/
│           ├── providers/
│           │   └── goals_provider.dart
│           └── widgets/
│               ├── goal_card.dart
│               └── goal_progress_indicator.dart
│
├── core/                                    # SHARED UTILITIES
│   ├── theme/
│   │   ├── buddy_theme.dart
│   │   ├── text_styles.dart
│   │   └── dimensions.dart
│   ├── widgets/                             # SHARED WIDGETS
│   │   ├── kid_friendly_button.dart
│   │   ├── progress_stepper.dart
│   │   └── celebration_overlay.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   └── animations.dart
│   └── constants/
│       └── app_constants.dart
│
└── shared/                                  # SHARED SERVICES
    ├── services/
    │   ├── storage_service.dart
    │   └── analytics_service.dart
    └── providers/
        └── shared_providers.dart

test/
├── models/
│   ├── buddy_test.dart                     # NEW
│   └── kid_profile_test.dart               # NEW
├── services/
│   └── buddy_service_test.dart             # NEW
└── screens/
    └── onboarding/
        ├── buddy_naming_screen_test.dart   # NEW
        └── kid_profile_screen_test.dart    # NEW

integration_test/
└── onboarding_flow_test.dart               # NEW

supabase/
└── migrations/
    └── 20241130000000_create_buddies.sql   # NEW
```

### Files to Modify

```
lib/
├── main.dart                               # Update routes
├── screens/
│   └── auth/
│       └── signup_screen.dart              # Add age-based routing
└── presentation/
    └── providers/
        └── providers.dart                  # Export new providers
```

### Files to Deprecate (Optional - keep for adults)

```
lib/screens/onboarding/
├── onboarding_screen.dart                  # Keep for adults or remove
├── survey_intro_screen.dart                # Keep for adults or remove
├── survey_basic_info_screen.dart           # Keep for adults or remove
├── survey_body_measurements_screen.dart    # Keep for adults or remove
├── survey_activity_goals_screen.dart       # Keep for adults or remove
└── survey_daily_targets_screen.dart        # Keep for adults or remove
```

---

## 🎨 DESIGN SPECS

### Color Palette (Kids)

```dart
class BuddyTheme {
  // Primary Colors
  static const oceanBlue = Color(0xFF4ECDC4);
  static const lightBlue = Color(0xFFF0F8FF);

  // Text Colors
  static const darkText = Color(0xFF2C3E50);
  static const lightText = Color(0xFF7F8C8D);

  // Accent Colors (for unlocks)
  static const teal = Color(0xFF26A69A);
  static const green = Color(0xFF66BB6A);
  static const purple = Color(0xFF9575CD);
  static const yellow = Color(0xFFFFD54F);
  static const orange = Color(0xFFFFB74D);
  static const pink = Color(0xFFF06292);
  static const navy = Color(0xFF5C6BC0);

  // Success/Error
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE74C3C);
}
```

### Typography

```dart
class BuddyTextStyles {
  static const title = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: BuddyTheme.darkText,
    height: 1.2,
  );

  static const subtitle = TextStyle(
    fontSize: 18,
    color: BuddyTheme.lightText,
    height: 1.4,
  );

  static const buttonLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );

  static const input = TextStyle(
    fontSize: 20, // Large for kids
    color: BuddyTheme.darkText,
  );
}
```

### Touch Targets

```dart
class BuddyDimensions {
  static const minTouchTarget = 48.0;     // Minimum tap target
  static const buttonHeight = 64.0;       // Large buttons
  static const ageButtonSize = 64.0;      // Age selector tiles
  static const spacing = 24.0;            // General spacing
  static const borderRadius = 32.0;       // Rounded corners
}
```

---

## 🚀 DEPLOYMENT CHECKLIST

### Pre-Launch

- [ ] All 5 onboarding screens implemented
- [ ] Buddy model and service created
- [ ] Database migration tested on staging
- [ ] State providers tested with real Supabase data
- [ ] Navigation flow tested end-to-end
- [ ] Unit tests passing (>80% coverage)
- [ ] Widget tests passing
- [ ] Integration test passing
- [ ] Accessibility audit completed
- [ ] COPPA compliance verified (minimal data collection)
- [ ] Parent consent flow reviewed
- [ ] Age validation working (7-12 only)

### Launch

- [ ] Feature flag enabled (if using hybrid approach)
- [ ] Analytics events tracked:
  - `onboarding_started`
  - `buddy_named`
  - `profile_completed`
  - `onboarding_completed`
- [ ] Error monitoring active (Sentry/Firebase Crashlytics)
- [ ] Performance monitoring active
- [ ] A/B test configured (if applicable)

### Post-Launch

- [ ] Monitor completion rate (target: >85%)
- [ ] Monitor average completion time (target: <90 seconds)
- [ ] Monitor skip rate on Step 4 (profile)
- [ ] Monitor buddy name diversity
- [ ] Collect user feedback (parent surveys)
- [ ] Iterate based on metrics

---

## 📊 SUCCESS METRICS

### Quantitative

| Metric                     | Target      | Current (Baseline) |
| -------------------------- | ----------- | ------------------ |
| Onboarding completion rate | >85%        | TBD                |
| Average completion time    | <90 seconds | TBD                |
| Buddy naming rate          | >95%        | TBD                |
| Profile completion rate    | >60%        | TBD                |
| Skip rate (Step 4)         | <40%        | TBD                |
| Day 1 retention            | >70%        | TBD                |
| Week 1 retention           | >50%        | TBD                |

### Qualitative

- [ ] Kids understand Buddy concept
- [ ] Parents feel onboarding is safe (COPPA)
- [ ] Buddy names are creative and appropriate
- [ ] Age selection is easy for kids
- [ ] Animations delight kids
- [ ] No confusion in flow

---

## 🔒 COPPA COMPLIANCE

### Data Collection (Minimized)

**Collected:**

- ✅ Buddy name (kid-chosen, no PII)
- ✅ Kid nickname (optional, no validation)
- ✅ Age (7-12 range only, no exact birthdate)
- ✅ Account creation timestamp

**NOT Collected:**

- ❌ Full name
- ❌ Email (parent's email only)
- ❌ Phone number
- ❌ Address
- ❌ Photo
- ❌ Exact birthdate
- ❌ Height/weight (removed from kids flow)
- ❌ Location data

### Parent Controls

- [ ] Parent email required for account creation
- [ ] Parent can view all kid data
- [ ] Parent can delete kid account
- [ ] Parent can export kid data
- [ ] Parent can disable features

---

## 🆘 ROLLBACK PLAN

If Buddy onboarding has critical issues:

### Step 1: Immediate (Feature Flag)

```dart
// Disable via remote config
RemoteConfig.instance.setBool('enable_buddy_onboarding', false);
```

### Step 2: Route Fallback

```dart
// Redirect to old flow
Navigator.pushReplacementNamed(context, '/survey_intro');
```

### Step 3: Database Rollback

```sql
-- If needed, remove buddies table
DROP TABLE IF EXISTS buddies;
```

### Step 4: Code Rollback

```bash
# Revert to previous commit
git revert <commit-hash>
git push origin main
```

---

## 📚 REFERENCES

- **Main Spec**: `docs/archive/feat-twist/MAIN-FEATURES.MD`
- **Current Onboarding**: `lib/screens/onboarding/README.md`
- **Riverpod Docs**: https://riverpod.dev/docs/introduction/getting_started
- **COPPA Guidelines**: https://www.ftc.gov/enforcement/rules/rulemaking-regulatory-reform-proceedings/childrens-online-privacy-protection-rule
- **Material Design (Kids)**: https://m3.material.io/foundations/accessible-design/overview

---

## 🎯 NEXT STEPS

1. **Review this spec** with team and stakeholders
2. **Get design approval** for UI mockups
3. **Set up feature flag** (if using hybrid approach)
4. **Create database migration** for buddies table
5. **Implement Phase 1** (Models and providers)
6. **Start with BuddyWelcomeScreen** (quick win)
7. **Iterate** based on user testing

---

**Document Version**: 1.0
**Last Updated**: November 29, 2024
**Author**: AI Agent (GitHub Copilot)
**Status**: ✅ Ready for Implementation
