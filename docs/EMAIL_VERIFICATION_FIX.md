# Email Verification Fix - Deep Link Navigation

## Problem

The deep link was working correctly (user was being verified), but the app wasn't automatically navigating to the survey screen after verification. The user remained stuck on the email verification screen.

## Root Cause

The `EmailVerificationScreen` wasn't listening to Supabase auth state changes. When the user clicked the email link:

1. ✅ Deep link opened the app
2. ✅ Supabase verified the user
3. ✅ Auth state changed to `signedIn`
4. ❌ But the EmailVerificationScreen didn't detect this change
5. ❌ User stayed on verification screen

## Solution

Updated `lib/screens/auth/email_verification_screen.dart` to:

1. **Listen to auth state changes** - Added `onAuthStateChange` listener
2. **Detect verification** - Check if `emailConfirmedAt` is set
3. **Auto-navigate** - Automatically redirect to survey when verified
4. **Real API calls** - Replaced mock code with actual Supabase calls

## Changes Made

### 1. Added Auth State Listener

```dart
void _listenToAuthChanges() {
  _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedIn && data.session != null) {
      final user = data.session!.user;
      if (user.emailConfirmedAt != null) {
        debugPrint('Email verified via deep link!');
        _onVerificationSuccess();
      }
    }
  });
}
```

### 2. Updated Manual Check

Changed from mock code to real Supabase API:

```dart
// Before: Simulated check
const isVerified = false;

// After: Real check
final response = await Supabase.instance.client.auth.refreshSession();
final user = response.user;
final isVerified = user?.emailConfirmedAt != null;
```

### 3. Updated Resend Email

Changed from mock to real API call:

```dart
// Before: Simulated
await Future.delayed(const Duration(milliseconds: 800));

// After: Real API
await Supabase.instance.client.auth.resend(
  type: OtpType.signup,
  email: email,
);
```

## Flow Now

### Email Verification Flow

1. User signs up → Email sent
2. User clicks email link on device
3. Deep link opens app → `com.oldstlabs.flowfit://auth-callback?code=...`
4. Supabase verifies user → `emailConfirmedAt` is set
5. Auth state changes → `AuthChangeEvent.signedIn`
6. **EmailVerificationScreen detects change** ✅
7. **Auto-navigates to survey** ✅

### Logs You'll See

```
D/com.llfbandit.app_links: Handled intent: com.oldstlabs.flowfit://auth-callback?code=...
I/flutter: supabase.supabase_flutter: INFO: handle deeplink uri
I/flutter: Auth state changed: AuthChangeEvent.signedIn
I/flutter: User signed in via deep link: user@example.com
I/flutter: Email verified via deep link!
```

## Testing

### Test 1: Email Verification (Full Flow)

```bash
# Run app
flutter run -d <device-id>

# Sign up with real email
# Click email link on device
# Should auto-navigate to survey ✅
```

### Test 2: Manual Check Button

```bash
# After clicking email link
# Press "I've Verified My Email" button
# Should detect verification and navigate ✅
```

### Test 3: Resend Email

```bash
# Press "Resend Verification Email"
# Check inbox for new email
# Click link → Should work ✅
```

## What Was Already Working

- ✅ Deep link configuration (AndroidManifest.xml)
- ✅ Deep link handler (DeepLinkHandler)
- ✅ PKCE flow (main.dart)
- ✅ Email redirect URL (AuthRepository)
- ✅ Supabase dashboard configuration

## What Was Fixed

- ✅ Auth state listener in EmailVerificationScreen
- ✅ Automatic navigation after verification
- ✅ Real API calls instead of mocks
- ✅ Proper cleanup of subscriptions

## Success Criteria

You'll know it's working when:

1. ✅ Sign up sends email
2. ✅ Click email link opens app
3. ✅ User is verified (check logs)
4. ✅ **App automatically navigates to survey** (NEW!)
5. ✅ No manual button press needed

## Debug Tips

If navigation still doesn't work:

1. **Check logs for**:
   ```
   I/flutter: Email verified via deep link!
   ```

2. **Verify user is authenticated**:
   ```dart
   final user = Supabase.instance.client.auth.currentUser;
   print('User: ${user?.email}, Verified: ${user?.emailConfirmedAt}');
   ```

3. **Check navigation context**:
   - Make sure `mounted` is true
   - Verify route exists in MaterialApp

## Files Modified

- `lib/screens/auth/email_verification_screen.dart` - Added auth listener and real API calls

## Related Documentation

- [Setup Guide](./MOBILE_DEEP_LINKING_SETUP.md)
- [Testing Guide](./DEEP_LINK_TESTING.md)
- [Checklist](./EMAIL_VERIFICATION_CHECKLIST.md)
