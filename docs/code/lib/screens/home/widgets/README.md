# Home Screen Widgets

This directory contains modular widgets for the FlowFit dashboard home screen.

## Available Widgets

### HomeHeader
App header with branding and notification indicator.

**Features:**
- App branding ("FlowFit")
- Notification bell icon with badge
- Badge displays count (or "9+" for counts > 9)
- Navigation to notifications screen on tap

**Usage:**
```dart
Scaffold(
  appBar: const HomeHeader(),
  body: // ... your content
)
```

### StatsSection
Daily fitness statistics display.

**Features:**
- Section header "Track Your Activity"
- StepsCard (full width) with progress bar
- Two-column grid with CompactStatsCard for calories and active time
- Loading skeleton placeholders
- Error state UI

**Usage:**
```dart
Column(
  children: [
    const StatsSection(),
    // ... other sections
  ],
)
```

### CTASection
Call-to-action buttons for starting workouts.

**Features:**
- Section header "Ready to move?"
- Primary button "Start a Workout"
- Secondary outlined button "Log a Run"
- Secondary outlined button "Record a Walk"
- Navigation with activity type parameters

**Usage:**
```dart
Column(
  children: [
    const CTASection(),
    // ... other sections
  ],
)
```

**Navigation Routes:**
- Start a Workout → `/active` (workout selection screen)
- Log a Run → `/active?type=run` (activity tracking with run pre-selected)
- Record a Walk → `/active?type=walk` (activity tracking with walk pre-selected)

## Complete Home Screen Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/home_header.dart';
import 'widgets/stats_section.dart';
import 'widgets/cta_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const HomeHeader(),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh providers
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              const StatsSection(),
              const SizedBox(height: 24),
              const CTASection(),
              const SizedBox(height: 24),
              // Add RecentActivitySection here when implemented
            ],
          ),
        ),
      ),
    );
  }
}
```

## Design Guidelines

All widgets follow these design principles:

- **Theme Consistency**: All colors use `theme.colorScheme`, all text styles use `theme.textTheme`
- **Card Styling**: 16px border radius, 16px padding, elevation 2, surface background
- **Button Sizing**: 56dp height for all buttons
- **Icon Sizing**: 24dp for all icons
- **Section Spacing**: Minimum 24dp between sections
- **Section Headers**: Use `titleLarge` with bold font weight

## Testing

Each widget has comprehensive unit tests in the `test/screens/home/widgets/` directory.

Run tests:
```bash
flutter test test/screens/home/widgets/
```
