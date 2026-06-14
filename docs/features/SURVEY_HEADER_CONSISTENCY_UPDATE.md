# Survey Header Consistency Update

## Changes Made

Updated the Activity & Goals screen to match the beautiful header style used in other survey screens.

### Before

```dart
const Row(
  children: [
    Icon(SolarIconsBold.running, color: AppTheme.primaryBlue, size: 24),
    SizedBox(width: 8),
    Text('Current Activity Level', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
  ],
)
```

### After

```dart
Row(
  children: [
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(SolarIconsBold.running, color: AppTheme.primaryBlue, size: 24),
    ),
    const SizedBox(width: 16),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Activity Level', style: titleLarge, bold, primaryBlue),
          const SizedBox(height: 4),
          Text('How active are you?', style: 14px, grey[600]),
        ],
      ),
    ),
  ],
)
```

## Updated Sections

### 1. Activity Level Section

- **Icon Badge**: Added rounded container with primary blue background (10% opacity)
- **Title**: Changed to primary blue color with titleLarge theme
- **Subtitle**: Added "How active are you?" in grey
- **Spacing**: Increased from 8px to 16px between icon and text

### 2. Goals Section

- **Icon Badge**: Added rounded container with primary blue background (10% opacity)
- **Title**: Changed to primary blue color with titleLarge theme
- **Subtitle**: Added "What do you want to achieve?" in grey
- **Spacing**: Increased from 8px to 16px between icon and text

## Consistency Achieved

All survey screens now share the same header pattern:

```
┌─────────────────────────────────────────┐
│  [Icon Badge]  Title                    │
│                Subtitle                 │
└─────────────────────────────────────────┘
```

**Screens with Consistent Headers:**

1. ✅ Survey Intro Screen
2. ✅ Survey Basic Info Screen
3. ✅ Survey Body Measurements Screen
4. ✅ Survey Activity Goals Screen (just updated)
5. ✅ Survey Daily Targets Screen

## Visual Design Elements

- **Icon Badge**: 12px padding, primary blue background (10% opacity), 12px border radius
- **Icon**: 24px size, primary blue color
- **Title**: titleLarge/headlineMedium theme, bold, primary blue
- **Subtitle**: 14px, grey[600]
- **Spacing**: 16px between icon badge and text column, 4px between title and subtitle

## Result

The Activity & Goals screen now has the same polished, professional appearance as all other survey screens, creating a cohesive and beautiful user experience throughout the onboarding flow.
