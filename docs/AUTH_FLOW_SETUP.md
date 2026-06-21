# FlowFit Authentication Flow Setup

## Overview
Complete authentication flow with loading screen, welcome screen, login, and signup screens following the FlowFit Style Guide.

## Created Files

### 1. Theme System
**File:** `lib/theme/app_theme.dart`
- Reusable theme based on FlowFit Style Guide
- Colors: Primary Blue (#3B82F6), Light Blue (#5DADE2), Cyan (#5DD9E2)
- Font: General Sans (configured, needs font files)
- Light and Dark theme support
- Consistent button, input, and card styling

### 2. Loading Screen
**File:** `lib/screens/loading_screen.dart`
- Animated splash screen with gradient background
- Fade and scale animations
- 3-second delay before navigating to welcome screen
- Shows FlowFit logo and loading indicator

### 3. Welcome Screen
**File:** `lib/screens/auth/welcome_screen.dart`
- First screen after loading
- Gradient background with brand colors
- "Get Started" button → navigates to signup
- "I Already Have an Account" button → navigates to login
- Shows app tagline and Galaxy Watch compatibility

### 4. Login Screen
**File:** `lib/screens/auth/login_screen.dart`
- Email and password fields with validation
- Password visibility toggle
- "Forgot Password?" link
- Link to signup screen
- Form validation:
  - Email format check
  - Password minimum 6 characters
- Loading state during authentication

### 5. Sign Up Screen
**File:** `lib/screens/auth/signup_screen.dart`
- Full name, email, password, and confirm password fields
- Password strength validation:
  - Minimum 8 characters
  - At least one uppercase letter
  - At least one number
- Terms and Conditions checkbox (required)
- Link to login screen
- Loading state during registration

## Navigation Flow

```
Loading Screen (3s)
    ↓
Welcome Screen
    ├─→ Sign Up → Sign Up Screen → Supabase Auth → Age Gate/Survey
    └─→ Login → Login Screen → Supabase Auth → Dashboard/Age Gate
```

## Routes Configuration

```dart
routes: {
  '/': LoadingScreen,
  '/welcome': WelcomeScreen,
  '/login': LoginScreen,
  '/signup': SignUpScreen,
  '/home': PhoneHomePage,
}
```

## Features

### ✅ Implemented
- Complete UI for all auth screens
- Form validation
- Loading states
- Navigation between screens
- Responsive design
- Dark mode support
- Reusable theme system
- Password visibility toggles
- Terms acceptance checkbox

### Future Enhancements
- Real Google/Apple OAuth provider flows
- Biometric authentication
- Remember me controls

## Usage

### Running the App
```bash
flutter run
```

### Testing the Flow
1. App opens with loading screen (3 seconds)
2. Welcome screen appears
3. Click "Get Started" to go to signup
4. Or click "I Already Have an Account" to go to login
5. Fill in forms and verify Supabase Auth handles signup/login

### Customizing Theme
Edit `lib/theme/app_theme.dart` to modify:
- Colors
- Typography
- Button styles
- Input field styles
- Card styles

## Design System

### Colors
- **Primary Blue:** `#3B82F6` - Main brand color
- **Light Blue:** `#5DADE2` - Secondary accent
- **Cyan:** `#5DD9E2` - Tertiary accent
- **Black:** `#000000` - Text and backgrounds
- **White:** `#FFFFFF` - Backgrounds and text
- **Light Gray:** `#F5F5F5` - Surface backgrounds
- **Dark Gray:** `#6B7280` - Secondary text

### Typography
- **Font Family:** General Sans (needs font files added)
- **Display:** 57px, 45px, 36px (bold)
- **Headline:** 32px, 28px, 24px (semi-bold)
- **Title:** 22px, 16px, 14px (semi-bold)
- **Body:** 16px, 14px, 12px (regular)
- **Label:** 14px, 12px, 11px (semi-bold)

### Components
- **Buttons:** 12px border radius, 16px vertical padding
- **Input Fields:** 12px border radius, outlined style
- **Cards:** 16px border radius, 2px elevation
- **Icons:** Material Icons (Solar icons can be added)

## Next Steps

1. **Add Font Files:**
   - Download General Sans font
   - Add to `assets/fonts/`
   - Update `pubspec.yaml`

2. **Backend Integration:**
   - Create authentication service
   - Implement API calls
   - Add error handling
   - Store auth tokens securely

3. **Add Icons:**
   - Consider adding Iconify/Solar icon package
   - Replace Material Icons where needed

4. **Enhanced Features:**
   - Biometric authentication
   - Remember me functionality
   - Social login (Google, Apple)
   - Email verification flow
   - Password reset flow

## File Structure

```
lib/
├── theme/
│   └── app_theme.dart          # Reusable theme system
├── screens/
│   ├── loading_screen.dart     # Splash/loading screen
│   ├── auth/
│   │   ├── welcome_screen.dart # Welcome/onboarding
│   │   ├── login_screen.dart   # Login form
│   │   └── signup_screen.dart  # Registration form
│   └── phone_home.dart         # Main app screen
└── main.dart                   # App entry point with routes
```

## Notes

- All screens are fully responsive
- Dark mode automatically follows system settings
- Form validation provides user-friendly error messages
- Loading states prevent multiple submissions
- Navigation uses named routes for easy management
- Theme is centralized for easy customization

---

**Status:** ✅ UI Complete - Backend integration pending
**Last Updated:** November 25, 2025
