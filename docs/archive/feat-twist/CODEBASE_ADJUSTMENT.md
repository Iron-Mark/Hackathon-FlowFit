# Codebase Documentation

## Project Overview

This is a Flutter-based wellness and fitness tracking application designed specifically for children aged 7-12 years old. The app focuses on promoting healthy habits through gamification, kid-friendly UX, and parental oversight features.

## Core Principles

### 1. Kid-Friendly UX (Ages 7-12)

- **Simple Navigation**: Clear, intuitive interfaces with minimal complexity
- **Visual Design**: Bright colors, large buttons, and engaging graphics
- **Age-Appropriate Language**: Simple, encouraging text that kids can understand
- **Accessibility**: Touch-friendly controls sized appropriately for smaller hands
- **Feedback**: Immediate visual and audio feedback for actions

### 2. Gamification

- **Achievements & Rewards**: Unlock badges and rewards for completing activities
- **Progress Tracking**: Visual progress bars and milestone celebrations
- **Challenges**: Fun, age-appropriate fitness and wellness challenges
- **Avatars & Customization**: Personalization options to increase engagement
- **Leaderboards**: Optional friendly competition (with parental controls)

### 3. Parental Oversight

- **Activity Monitoring**: Parents can view their child's activity and progress
- **Privacy Controls**: Parental approval for social features
- **Safety Features**: Age-appropriate content filtering
- **Reports**: Regular summaries of child's wellness activities
- **Settings Management**: Parents control app permissions and features

## Technology Stack

- **Framework**: Flutter (cross-platform mobile development)
- **Backend**: Supabase (authentication, database, real-time features)
- **State Management**: Provider/Riverpod pattern
- **Platform Support**: iOS, Android, Web, Windows, macOS, Linux

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── providers/                # State management
├── screens/                  # UI screens
├── services/                 # Business logic & API calls
├── widgets/                  # Reusable UI components
└── utils/                    # Helper functions & constants

assets/                       # Images, fonts, animations
supabase/                     # Database schemas & migrations
test/                         # Unit & widget tests
```

## Key Features

### Wellness Tracking

- **Step Counter**: Track daily steps with visual progress
- **Activity Tracking**: Log different types of physical activities
- **GPS Tracking**: Map-based activity tracking for running/walking
- **Heart Rate Monitoring**: BPM tracking during activities
- **Measurement Units**: Toggle between metric/imperial units

### User Experience

- **Onboarding**: Kid-friendly introduction to the app
- **Surveys**: Health and wellness questionnaires
- **Achievements**: Unlock rewards for reaching goals
- **Sharing**: Share achievements with parent approval
- **Email Verification**: Secure account setup with parental email

### Parental Features

- **Dashboard**: Overview of child's activities
- **Controls**: Manage privacy and feature settings
- **Reports**: Weekly/monthly activity summaries
- **Notifications**: Alerts for milestones and activities

## Development Guidelines

### UI/UX Standards

1. **Colors**: Use bright, cheerful colors from the app theme
2. **Typography**: Large, readable fonts (minimum 16sp for body text)
3. **Buttons**: Minimum 48x48 logical pixels for touch targets
4. **Icons**: Simple, recognizable icons with labels
5. **Animations**: Smooth, delightful transitions (not too fast)
6. **Error Messages**: Friendly, non-technical language

### Code Standards

1. **Naming**: Use clear, descriptive names for variables and functions
2. **Comments**: Document complex logic and kid-safety features
3. **Error Handling**: Graceful failures with kid-friendly messages
4. **Testing**: Write tests for critical user flows
5. **Accessibility**: Support screen readers and accessibility features

### Safety & Privacy

1. **Data Protection**: Minimal data collection, secure storage
2. **COPPA Compliance**: Follow children's privacy regulations
3. **Parental Consent**: Require parent approval for sensitive features
4. **Content Filtering**: Age-appropriate content only
5. **No Ads**: Ad-free experience for children

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Supabase account and project

### Installation

```bash
# Clone the repository
git clone <repository-url>

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Configuration

1. Set up Supabase project and copy credentials
2. Configure environment variables
3. Update `pubspec.yaml` with required dependencies
4. Run database migrations in `supabase/` folder

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

## Building for Production

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Key Files Reference

- `pubspec.yaml` - Dependencies and app configuration
- `analysis_options.yaml` - Linting rules
- `build.yaml` - Build configuration
- `clean_build.bat` - Clean build script for Windows

## Documentation Files

- `README.md` - Project overview
- `docs/QUICK_START.md` - Quick start guide
- `docs/TROUBLESHOOTING.md` - Common issues and solutions
- `WELLNESS_TRACKER_COMPLETE.md` - Wellness feature documentation
- `AUTH_GUARDS_SUMMARY.md` - Authentication flow documentation
- `DEEP_LINK_QUICK_REF.md` - Deep linking reference

## Contributing

When contributing to this project, remember:

1. Keep the target audience (ages 7-12) in mind
2. Test features with kid-friendly scenarios
3. Ensure parental controls remain functional
4. Follow the established code style
5. Update documentation for new features

## Support & Resources

- Flutter Documentation: https://flutter.dev/docs
- Supabase Documentation: https://supabase.io/docs
- Material Design Guidelines: https://material.io/design
- COPPA Compliance: https://www.ftc.gov/enforcement/rules/rulemaking-regulatory-reform-proceedings/childrens-online-privacy-protection-rule

## License

[Add your license information here]

---

**Remember**: Every feature, every line of code, every design decision should prioritize the safety, privacy, and positive experience of children aged 7-12.
