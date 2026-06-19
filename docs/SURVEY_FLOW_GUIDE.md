# 📋 Optimized Survey Flow - Implementation Guide

## 🎯 Overview

This document describes the new 4-screen survey flow with privacy consent moved to the signup screen. The flow is designed to be quick (under 2 minutes), skippable, and focused on personalization.

## 🔄 Flow Architecture

```
Welcome → Signup (with privacy) → Survey Intro → 4 Survey Screens → Dashboard
                                       ↓
                                  (All skippable)
```

## 📱 Screen Breakdown

### 1. **Updated Signup Screen** (`signup_screen.dart`)
**Location**: `lib/screens/auth/signup_screen.dart`

**New Features**:
- Email field
- Password field (min 8 characters)
- Confirm password field
- **Privacy Consent Section**:
  - ✅ Terms of Service & Privacy Policy (required)
  - ✅ Galaxy Watch data collection consent (required)
  - ☐ Marketing emails (optional)

**Navigation**:
- On successful signup → `/survey_intro`
- Cannot proceed without required consents

---

### 2. **Survey Intro Screen** (`survey_intro_screen.dart`)
**Location**: `lib/screens/onboarding/survey_intro_screen.dart`

**Purpose**: Motivate users to complete the survey

**Features**:
- Animated illustration
- "Quick Setup (2 Minutes)" title
- Benefits list:
  - Daily calorie target 🔥
  - Heart rate zones 💓
  - Personalized goals 🎯
- Progress dots (4 circles)
- "LET'S PERSONALIZE" button
- "I'll do this later →" skip option

**Navigation**:
- Continue → `/survey_basic_info`
- Skip → `/dashboard`

---

### 3. **Screen 1: Basic Info** (`survey_basic_info_screen.dart`)
**Location**: `lib/screens/onboarding/survey_basic_info_screen.dart`

**Data Collected**:
- First name (text input)
- Birthday (date picker with age calculation)
- Biological sex (Male/Female/Other radio buttons)

**Features**:
- Progress indicator (1/4)
- Real-time age calculation from birthday
- Info tooltip explaining why data is needed
- All fields optional with smart defaults

**Navigation**:
- Continue → `/survey_body_measurements`
- Skip → `/dashboard`
- Back → Previous screen

**Default Values** (if skipped):
- Name: "User"
- Age: 30 years
- Sex: Other

---

### 4. **Screen 2: Body Measurements** (`survey_body_measurements_screen.dart`)
**Location**: `lib/screens/onboarding/survey_body_measurements_screen.dart`

**Data Collected**:
- Unit system (Metric/Imperial toggle)
- Height (dropdown for imperial, slider for metric)
- Weight (slider with +/- buttons)

**Features**:
- Progress indicator (2/4)
- Real-time unit conversion
- BMI calculation with color-coded status:
  - Blue: Underweight (<18.5)
  - Green: Healthy (18.5-25) ✓
  - Orange: Overweight (25-30)
  - Red: Obese (>30)
- Interactive sliders and dropdowns
- Info tooltip about calorie burn calculation

**Navigation**:
- Continue → `/survey_activity_goals`
- Skip → `/dashboard`
- Back → `/survey_basic_info`

**Default Values** (if skipped):
- Height: 170cm (5'7")
- Weight: 70kg (154lbs)
- Unit: Metric

---

### 5. **Screen 3: Activity & Goals** (`survey_activity_goals_screen.dart`)
**Location**: `lib/screens/onboarding/survey_activity_goals_screen.dart`

**Data Collected**:

**Activity Level** (radio selection):
- 📱 Sedentary (1.2× multiplier) - Desk job, little exercise
- 🚴 Moderately Active (1.55× multiplier) - Exercise 3-5 times/week
- 🏋️ Very Active (1.725× multiplier) - Daily intense exercise

**Fitness Goal** (radio selection):
- 🔥 Lose Weight (-500 cal/day)
- ⚖️ Maintain Weight (0 cal adjustment)
- 💪 Build Muscle (+300 cal/day)
- ❤️ Improve Cardio (0 cal adjustment)

**Features**:
- Progress indicator (3/4)
- Color-coded goal cards
- Clear multiplier/calorie adjustment info
- Large, easy-to-tap cards

**Navigation**:
- Continue → `/survey_daily_targets`
- Skip → `/dashboard`
- Back → `/survey_body_measurements`

**Default Values** (if skipped):
- Activity: Moderately active (1.55×)
- Goal: Maintain weight

---

### 6. **Screen 4: Daily Targets** (`survey_daily_targets_screen.dart`)
**Location**: `lib/screens/onboarding/survey_daily_targets_screen.dart`

**Data Collected**:
- Target calories (calculated, adjustable via dialog)
- Target steps (quick select: 5K, 10K, 12K, 15K)
- Target active minutes (quick select: 20, 30, 45, 60)
- Target water intake (quick select: 1.5L, 2L, 2.5L, 3L)

**Features**:
- Progress indicator (4/4)
- **Calorie Target Card**:
  - Shows calculated value (e.g., 2,450 cal)
  - Displays calculation basis (age, height, weight, activity, goal)
  - "Adjust" button opens slider dialog
- **Visual Progress Bars** for each metric
- **Quick Select Chips** for easy value selection
- Color-coded targets:
  - 🔥 Calories: Orange
  - 👟 Steps: Green
  - ⏱️ Active Minutes: Purple
  - 💧 Water: Blue
- Info note about adjusting in settings later

**Navigation**:
- "✓ COMPLETE & START APP" → `/dashboard`
- "Use these defaults" → `/dashboard`
- Back → `/survey_activity_goals`

**Default Values**:
- Calories: 2,000 (or calculated from profile)
- Steps: 10,000
- Active Minutes: 30
- Water: 2.0L

---

## 🔐 Updated Login Screen

**Changes**:
- All login methods now navigate to `/dashboard` instead of `/home`
- Maintains existing UI and functionality

---

## 🎨 Design Principles

### Visual Consistency
- **Primary Color**: AppTheme.primaryBlue
- **Progress Indicators**: 4-segment bar at top of each screen
- **Card Style**: Rounded corners (12px), subtle shadows
- **Typography**: Bold titles, regular body text, gray hints

### Interaction Patterns
- **Radio Buttons**: Visual feedback with color change
- **Sliders**: Real-time value updates
- **Quick Select**: Chip-style buttons for common values
- **Skip Options**: Always available, non-intrusive

### Accessibility
- Large touch targets (min 44x44)
- High contrast text
- Clear labels and hints
- Keyboard navigation support

---

## 📊 Data Flow

### Survey State Management (Recommended)

```dart
class SurveyState extends ChangeNotifier {
  // Screen 1: Basic Info
  String? firstName;
  DateTime? dateOfBirth;
  String? biologicalSex;
  
  // Screen 2: Body Measurements
  double? heightCm;
  double? weightKg;
  String unitSystem = 'metric';
  
  // Screen 3: Activity & Goals
  String? activityLevel;
  String? fitnessGoal;
  
  // Screen 4: Daily Targets
  int? targetCaloriesDaily;
  int targetStepsDaily = 10000;
  int targetActiveMinutesDaily = 30;
  double targetWaterLitersDaily = 2.0;
  
  // Calculated fields
  int? get age { /* ... */ }
  double? get bmi { /* ... */ }
  int? get bmr { /* ... */ }
  int? get tdee { /* ... */ }
}
```

### Calculation Formulas

**BMI**:
```dart
bmi = weight_kg / (height_m * height_m)
```

**BMR (Basal Metabolic Rate)**:
```dart
// Mifflin-St Jeor Equation
BMR_male = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) + 5
BMR_female = (10 × weight_kg) + (6.25 × height_cm) - (5 × age) - 161
```

**TDEE (Total Daily Energy Expenditure)**:
```dart
TDEE = BMR × activity_multiplier
// Sedentary: 1.2
// Moderate: 1.55
// Very Active: 1.725
```

**Target Calories**:
```dart
Target = TDEE + goal_adjustment
// Lose weight: -500
// Maintain: 0
// Build muscle: +300
// Improve cardio: 0
```

---

## 🚀 Testing Checklist

### Signup Screen
- [ ] Email validation works
- [ ] Password must be 8+ characters
- [ ] Confirm password matches
- [ ] Cannot submit without required consents
- [ ] Optional marketing checkbox works
- [ ] Terms/Policy links show placeholder

### Survey Flow
- [ ] Can skip from any screen
- [ ] Back button works correctly
- [ ] Progress indicators update
- [ ] All default values are sensible

### Screen 1: Basic Info
- [ ] Name input accepts text
- [ ] Date picker opens and selects date
- [ ] Age calculates correctly
- [ ] Sex selection works
- [ ] Can navigate forward

### Screen 2: Body Measurements
- [ ] Unit toggle switches correctly
- [ ] Height inputs work (both systems)
- [ ] Weight slider updates value
- [ ] +/- buttons adjust weight
- [ ] BMI calculates and shows correct status
- [ ] Unit conversion displays correctly

### Screen 3: Activity & Goals
- [ ] Activity level selection works
- [ ] Goal selection works
- [ ] Cards highlight when selected
- [ ] Can select one of each

### Screen 4: Daily Targets
- [ ] Calorie adjust dialog opens
- [ ] Quick select chips work for all metrics
- [ ] Progress bars display correctly
- [ ] Complete button navigates to dashboard

### Navigation
- [ ] Login goes to dashboard
- [ ] Signup goes to survey intro
- [ ] Survey completion goes to dashboard
- [ ] Skip always goes to dashboard

---

## 📝 Future Enhancements

### Phase 2 (Backend Integration)
- [ ] Save survey data to Supabase
- [ ] Create `user_profiles` table
- [ ] Create `user_consents` table
- [ ] Implement profile completion tracking
- [ ] Add "Complete Profile" banner in dashboard

### Phase 3 (Advanced Features)
- [ ] Profile editing in settings
- [ ] Goal progress tracking
- [ ] Personalized recommendations
- [ ] Achievement system
- [ ] Social features

---

## 🎯 Key Benefits

✅ **Privacy First**: Consent collected upfront, clearly explained  
✅ **Quick Setup**: Under 2 minutes to complete  
✅ **Flexible**: All screens skippable with smart defaults  
✅ **Visual**: Real-time calculations and feedback  
✅ **Personalized**: Tailored targets based on user data  
✅ **Professional**: Clean, modern UI with smooth transitions  

---

## 📞 Support

For questions or issues with the survey flow implementation, refer to:
- Main app documentation: `README.md`
- Architecture guide: `docs/code/lib/ARCHITECTURE.md`
- Dashboard navigation: `DASHBOARD_NAVIGATION_FLOW.md`
