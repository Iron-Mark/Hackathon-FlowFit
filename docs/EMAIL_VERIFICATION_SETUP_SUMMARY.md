# Email Verification Setup - Quick Start

This is your quick reference for setting up and testing email verification with deep linking in FlowFit.

## What We've Set Up

1. ✅ **Android Deep Link Configuration** - AndroidManifest.xml updated
2. ✅ **Deep Link Handler** - Utility to process auth callbacks
3. ✅ **Supabase Integration** - PKCE flow enabled in main.dart
4. ✅ **Documentation** - Complete guides for setup and testing

## Quick Start (5 Minutes)

### 1. Configure Supabase Dashboard (2 min)

Go to: https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/url-configuration

**Add these Redirect URLs**:
```
com.msiazondev.flowfit://auth-callback
com.msiazondev.flowfit.dev://auth-callback
http://localhost:3000/**
```

**Set Site URL to**:
```
com.msiazondev.flowfit://auth-callback
```

### 2. Update Email Template (1 min)

Go to: https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/templates

Make sure the "Confirm signup" template uses:
```html
<a href="{{ .ConfirmationURL }}">Confirm your email</a>
```

### 3. Test It (2 min)

```bash
# Rebuild the app with new manifest
flutter run -d <your-device-id>

# Test deep link opens app
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.msiazondev.flowfit://auth-callback" \
  com.msiazondev.flowfit
```

## Testing Email Verification

### Option A: Real Email Test

1. Sign up with your real email
2. Check inbox for verification email
3. Click the link on your device
4. App should open and verify automatically

### Option B: ADB Test (No Email Needed)

```bash
# Simulate auth callback
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.msiazondev.flowfit://auth-callback?type=signup&token=test" \
  com.msiazondev.flowfit

# Watch logs
adb logcat | grep -i "deep link\|auth"
```

## Current Issue: Email Verification Not Working?

Based on your logs, here's what to check:

### 1. Check Supabase Dashboard Config

- [ ] Redirect URLs are added (see above)
- [ ] Site URL is set to deep link
- [ ] Email confirmation is enabled

### 2. Check Email Template

The template should use `{{ .ConfirmationURL }}` which automatically includes the redirect URL.

### 3. Update Your Sign Up Code

Make sure you're passing `emailRedirectTo`:

```dart
// In your signup screen
final response = await Supabase.instance.client.auth.signUp(
  email: email,
  password: password,
  emailRedirectTo: 'com.msiazondev.flowfit://auth-callback', // Add this!
);
```

### 4. Test Deep Link Works

```bash
# This should open your app
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.msiazondev.flowfit://auth-callback" \
  com.msiazondev.flowfit
```

If the app doesn't open, check AndroidManifest.xml.

## Files Changed

1. **android/app/src/main/AndroidManifest.xml** - Added deep link intent filter
2. **lib/main.dart** - Added PKCE flow and deep link initialization
3. **lib/utils/deep_link_handler.dart** - New file for handling deep links

## Documentation Created

1. **docs/MOBILE_DEEP_LINKING_SETUP.md** - Complete setup guide
2. **docs/SUPABASE_DASHBOARD_CONFIG.md** - Dashboard configuration reference
3. **docs/DEEP_LINK_TESTING.md** - Testing guide with ADB commands
4. **docs/EMAIL_VERIFICATION_SETUP_SUMMARY.md** - This file

## Next Steps

### Immediate (Testing)

1. Configure Supabase Dashboard (see above)
2. Test deep link with ADB
3. Test with real email signup
4. Check logs for any errors

### Before Production

1. Confirm production package identity is `com.msiazondev.flowfit`
2. Confirm deep link schemes match the production package
3. Remove development schemes
4. Test on multiple devices
5. Set up custom SMTP for better email delivery

## Common Issues

### App doesn't open from email link

**Cause**: Redirect URLs not configured in Supabase

**Fix**: Add redirect URLs in dashboard (see Quick Start #1)

### Email link opens browser instead of app

**Cause**: Android needs to learn the association

**Fix**: Try clicking the link multiple times, or use ADB to test

### Email not sending

**Cause**: Email confirmation might be disabled

**Fix**: Enable in Auth Settings: https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/providers

### Token expired error

**Cause**: Email links expire after 24 hours

**Fix**: Request new verification email (resend button in app)

## Getting Help

If you're still having issues:

1. Check Supabase logs: https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/logs/explorer
2. Check app logs: `adb logcat | grep -i "flutter\|auth"`
3. Review the detailed guides in `docs/` folder
4. Check Supabase Discord or GitHub issues

## Resources

- [Supabase Auth Deep Linking](https://supabase.com/docs/guides/auth/auth-deep-linking/auth-deep-linking)
- [Flutter Deep Linking](https://docs.flutter.dev/ui/navigation/deep-linking)
- [Android App Links](https://developer.android.com/training/app-links)

---

**Quick Links**:
- [Setup Guide](./MOBILE_DEEP_LINKING_SETUP.md)
- [Dashboard Config](./SUPABASE_DASHBOARD_CONFIG.md)
- [Testing Guide](./DEEP_LINK_TESTING.md)
