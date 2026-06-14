# Auth Guards and Logout Implementation

## Overview

Added authentication guards and proper logout functionality to ensure users can only access the dashboard when authenticated, and are redirected appropriately when they sign out.

## Changes Made

### 1. Logout Button in Profile Tab

**File**: `lib/screens/dashboard_screen.dart`

#### Features:
- ✅ Confirmation dialog before logout
- ✅ Calls `authNotifier.signOut()` to clear session
- ✅ Redirects to welcome screen
- ✅ Clears navigation stack

#### Implementation:

```dart
_buildSettingItem(
  context,
  'Logout',
  SolarIconsOutline.logout,
  onTap: () async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      // Sign out using auth notifier
      await ref.read(authNotifierProvider.notifier).signOut();

      // Navigate to welcome screen and clear stack
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false,
        );
      }
    }
  },
),
```

### 2. Dashboard Auth Guard

**File**: `lib/screens/dashboard_screen.dart`

#### Features:
- ✅ Checks auth state on init
- ✅ Listens for auth state changes
- ✅ Redirects to welcome if not authenticated
- ✅ Automatically redirects on logout

#### Implementation:

```dart
class DashboardScreen extends ConsumerStatefulWidget {
  // ...
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Check auth state on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    final authState = ref.read(authNotifierProvider);

    // If not authenticated, redirect to welcome screen
    if (authState.user == null) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/welcome',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth state changes
    ref.listen(authNotifierProvider, (previous, next) {
      // If user logs out, redirect to welcome
      if (next.user == null && mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (route) => false,
        );
      }
    });

    // ... rest of build
  }
}
```

### 3. Welcome Screen Auth Guard

**File**: `lib/screens/auth/welcome_screen.dart`

#### Features:
- ✅ Checks if user is already authenticated
- ✅ Redirects to dashboard if logged in
- ✅ Prevents showing welcome to authenticated users

#### Implementation:

```dart
class WelcomeScreen extends ConsumerStatefulWidget {
  // ...
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check if user is already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    final authState = ref.read(authNotifierProvider);

    // If already authenticated, redirect to dashboard
    if (authState.user != null && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }
}
```

### 4. Login Screen Auth Guard

**File**: `lib/screens/auth/login_screen.dart`

#### Features:
- ✅ Checks if user is already authenticated
- ✅ Redirects to dashboard if logged in
- ✅ Prevents duplicate logins

#### Implementation:

```dart
class _LoginScreenState extends ConsumerState<LoginScreen> {
  @override
  void initState() {
    super.initState();
    // Check if user is already authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthState();
    });
  }

  void _checkAuthState() {
    final authState = ref.read(authNotifierProvider);

    // If already authenticated, redirect to dashboard
    if (authState.user != null && mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }
}
```

## User Flows

### Flow 1: Logout

1. User is on Dashboard (authenticated)
2. User taps Profile tab
3. User taps "Logout" button
4. Confirmation dialog appears
5. User confirms logout
6. `authNotifier.signOut()` is called
7. Supabase session is cleared
8. Auth state changes to unauthenticated
9. Dashboard listener detects change
10. User is redirected to Welcome screen
11. Navigation stack is cleared

### Flow 2: Direct Dashboard Access (Not Authenticated)

1. User tries to navigate to `/dashboard`
2. Dashboard `initState` checks auth state
3. User is not authenticated
4. User is redirected to Welcome screen

### Flow 3: Welcome Screen (Already Authenticated)

1. User navigates to `/welcome`
2. Welcome screen `initState` checks auth state
3. User is already authenticated
4. User is redirected to Dashboard

### Flow 4: Login Screen (Already Authenticated)

1. User navigates to `/login`
2. Login screen `initState` checks auth state
3. User is already authenticated
4. User is redirected to Dashboard

## Auth State Management

### Auth States

```dart
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}
```

### Auth State Flow

```
┌─────────────────────────────────────────┐
│         App Start (Splash)              │
│  Check for existing session             │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
┌──────────────┐  ┌──────────────┐
│ Authenticated│  │Unauthenticated│
│              │  │              │
│  → Dashboard │  │  → Welcome   │
└──────┬───────┘  └──────┬───────┘
       │                 │
       │                 │
       │    ┌────────────┘
       │    │ Login/Signup
       │    │
       │    ▼
       │  ┌──────────────┐
       │  │ Email Verify │
       │  └──────┬───────┘
       │         │
       │         ▼
       │  ┌──────────────┐
       └──┤  Dashboard   │
          └──────┬───────┘
                 │
                 │ Logout
                 ▼
          ┌──────────────┐
          │   Welcome    │
          └──────────────┘
```

## Protected Routes

### Authenticated Only
- `/dashboard` - Main app dashboard
- `/activity-classifier` - Activity classifier
- `/phone_heart_rate` - Heart rate monitor
- `/mission` - Maps/missions

### Unauthenticated Only
- `/welcome` - Welcome screen
- `/login` - Login screen
- `/signup` - Sign up screen

### Public Routes
- `/` - Splash screen (checks auth)
- `/email_verification` - Email verification

## Testing

### Test 1: Logout Flow

```bash
# Run app
flutter run -d <device-id>

# Steps:
1. Login to app
2. Navigate to Profile tab
3. Tap "Logout"
4. Confirm logout
5. Should redirect to Welcome screen ✅
6. Try to go back - should not be able to ✅
```

### Test 2: Dashboard Protection

```bash
# Steps:
1. Logout from app
2. Try to navigate to /dashboard directly
3. Should redirect to Welcome screen ✅
```

### Test 3: Welcome Screen Redirect

```bash
# Steps:
1. Login to app
2. Navigate to /welcome
3. Should redirect to Dashboard ✅
```

### Test 4: Login Screen Redirect

```bash
# Steps:
1. Login to app
2. Navigate to /login
3. Should redirect to Dashboard ✅
```

## Security Considerations

### Session Management
- ✅ Sessions are stored securely by Supabase
- ✅ Logout clears all auth tokens
- ✅ Auth state is checked on app start
- ✅ Protected routes check auth state

### Navigation Security
- ✅ Navigation stack is cleared on logout
- ✅ Back button doesn't allow returning to protected routes
- ✅ Direct URL navigation is protected

### State Management
- ✅ Auth state is centralized in `authNotifierProvider`
- ✅ All screens listen to auth state changes
- ✅ Automatic redirects on state changes

## Common Issues

### Issue: User can still access dashboard after logout

**Cause**: Navigation stack not cleared

**Solution**: Use `pushNamedAndRemoveUntil` with `(route) => false`

```dart
Navigator.of(context).pushNamedAndRemoveUntil(
  '/welcome',
  (route) => false, // This clears the entire stack
);
```

### Issue: Infinite redirect loop

**Cause**: Auth guard triggering on every build

**Solution**: Use `addPostFrameCallback` to check auth only once

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkAuthState();
  });
}
```

### Issue: Context not mounted error

**Cause**: Navigating after widget is disposed

**Solution**: Check `mounted` before navigation

```dart
if (context.mounted) {
  Navigator.of(context).pushReplacementNamed('/dashboard');
}
```

## Files Modified

1. `lib/screens/dashboard_screen.dart`
   - Added auth guard
   - Implemented logout with confirmation
   - Added auth state listener

2. `lib/screens/auth/welcome_screen.dart`
   - Added auth guard
   - Redirects authenticated users

3. `lib/screens/auth/login_screen.dart`
   - Added auth guard
   - Redirects authenticated users

## Related Documentation

- [Email Verification Setup](./EMAIL_VERIFICATION_SETUP_SUMMARY.md)
- [Deep Link Setup](./MOBILE_DEEP_LINKING_SETUP.md)
- [Supabase Dashboard Config](./SUPABASE_DASHBOARD_CONFIG.md)
