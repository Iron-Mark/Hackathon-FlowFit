# Profile Module

This module contains all profile and settings-related screens for the FlowFit app.

## Structure

```
profile/
├── README.md                                    # Module documentation
├── settings/                                    # Settings screens
│   ├── settings_screen.dart                    # Main settings hub
│   ├── change_password_screen.dart             # Change password
│   ├── delete_account_screen.dart              # Delete account
│   └── general/                                # General settings
│       ├── privacy_policy_screen.dart          # Privacy policy
│       ├── notification_settings_screen.dart   # Notifications
│       ├── app_integration_screen.dart         # App integrations
│       ├── language_settings_screen.dart       # Language selection
│       ├── unit_settings_screen.dart           # Units (Metric/Imperial)
│       ├── terms_of_service_screen.dart        # Terms of service
│       ├── help_support_screen.dart            # Help & support
│       └── about_us_screen.dart                # About Us & Team
└── goals/                                       # Goals screens
    ├── weight_goals_screen.dart                # Weight goals
    ├── fitness_goals_screen.dart               # Fitness goals
    └── nutrition_goals_screen.dart             # Nutrition goals
```

## Navigation Flow

```
Profile Tab (dashboard_screen.dart)
  └── Settings Icon (⚙️)
      └── Settings Screen
          ├── General Settings
          │   ├── Privacy Policy
          │   ├── Notification Reminder
          │   └── App Integration
          ├── Account
          │   ├── Language
          │   └── Units
          └── About
              ├── Terms of Service
              ├── Help & Support
              ├── About Us (Team Info)
```

## Features

### Settings Screen

- Central hub for all app settings
- Organized into sections: General Settings, Account, About
- Clean card-based UI with icons

### General Settings

#### Privacy Policy Screen

- Complete privacy policy document
- Sectioned content for easy reading
- Contact information

#### Notification Settings Screen

- Toggle switches for different notification types
- Activity Reminders (Workout, Meal, Water, Sleep)
- Progress & Updates (Achievements, Weekly Reports)
- Local persistence for changed reminder preferences

#### App Integration Screen

- Shows integration readiness for health, wearable, social, and productivity
  providers without presenting unsupported providers as connectable.
- Unsupported third-party providers expose a Details action that states direct
  account sync is not available in this build.
- Samsung Health routes to the real Wellness setup flow for Galaxy Watch sensor
  permission and connection checks.

#### Language Settings Screen

- 12 supported languages
- Native language names displayed
- Visual selection feedback
- Local persistence for selected language

#### Unit Settings Screen

- Measurement system selection (Metric/Imperial)
- Individual unit preferences (Distance, Weight, Height, Temperature)
- Auto-updates when system changes
- Tappable individual unit pickers with local persistence

#### Terms of Service Screen

- Complete terms document
- Legal information and user agreements
- Contact information

#### Help & Support Screen

- Quick actions (Email Support, Live Chat, Report Bug)
- FAQ section with expandable questions
- Contact information and support hours

#### About Us Screen

- FlowFit branding and mission
- **Hackathon Development Team:**
  - Jam Emmanuel Villarosa - ML/AI Engineer & Project Leader
  - Ken Patrick Garcia - Full-stack Engineer
  - Mark Angelo Siazon - UI/UX Designer & Front-end Developer
  - Exequel Adizon - UI/UX Designer & Front-end Developer
- Project information (version, build, platform)
- Contact information

### Account Settings

#### Change Password Screen

- Current password verification
- New password with confirmation
- Form validation
- Supabase reauthentication and password update
- Success and failure feedback

#### Delete Account Screen

- Warning messages
- Password confirmation
- Checkbox confirmation
- Double confirmation dialog
- Permanent deletion

### Goals

#### Weight Goals Screen

- Current weight input
- Goal weight input
- Weekly goal selection
- Progress summary

#### Fitness Goals Screen

- Activity level selection
- Workouts per week slider
- Minutes per workout slider
- Multiple fitness goals selection
- Fitness plan summary

#### Nutrition Goals Screen

- Daily calorie goal
- Custom macros toggle
- Protein, carbs, fats inputs
- Nutrition plan summary

## Routes

All routes are defined in `lib/main.dart`:

**Settings:**

- `/settings` - Main settings screen
- `/change-password` - Change password
- `/delete-account` - Delete account

**General Settings:**

- `/privacy-policy` - Privacy policy
- `/notification-settings` - Notification preferences
- `/app-integration` - App integrations
- `/language-settings` - Language selection
- `/unit-settings` - Unit preferences
- `/terms-of-service` - Terms of service
- `/help-support` - Help & support
- `/about-us` - About Us & Team

**Goals:**

- `/weight-goals` - Weight goals
- `/fitness-goals` - Fitness goals
- `/nutrition-goals` - Nutrition goals

## Design Principles

- **Modular**: Each screen is self-contained and reusable
- **Organized**: Clear folder structure by feature
- **Consistent**: All screens follow the same design language
- **Accessible**: Proper touch targets, semantic labels, and navigation
- **Responsive**: Adapts to different screen sizes
- **User-friendly**: Clear labels, helpful descriptions, visual feedback
