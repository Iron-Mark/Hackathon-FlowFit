# Deep Link Quick Reference

## 🎯 What You Need to Do Now

### 1. Configure Supabase (2 minutes)

**URL**: https://supabase.com/dashboard/project/REPLACE_WITH_FLOWFIT_DEV_PROJECT_REF/auth/url-configuration

**Site URL**:
```
com.oldstlabs.flowfit://auth-callback
```

**Redirect URLs** (add all three):
```
com.oldstlabs.flowfit://auth-callback
com.oldstlabs.flowfit.dev://auth-callback
http://localhost:3000/**
```

### 2. Test It (1 minute)

```bash
# Rebuild app
flutter run -d <device-id>

# Test deep link
adb shell am start -W -a android.intent.action.VIEW -d "com.oldstlabs.flowfit://auth-callback" com.oldstlabs.flowfit
```

### 3. Test Email Flow (3 minutes)

1. Sign up with real email
2. Check inbox
3. Click link on device
4. App opens → User verified ✅

## 🔍 Quick Debug

```bash
# Watch logs
adb logcat | grep -i "deep link\|auth"

# Check if app opens
adb shell am start -W -a android.intent.action.VIEW -d "com.oldstlabs.flowfit://auth-callback" com.oldstlabs.flowfit
```

## 📚 Full Documentation

- **Setup**: `docs/MOBILE_DEEP_LINKING_SETUP.md`
- **Dashboard**: `docs/SUPABASE_DASHBOARD_CONFIG.md`
- **Testing**: `docs/DEEP_LINK_TESTING.md`
- **Checklist**: `docs/EMAIL_VERIFICATION_CHECKLIST.md`
- **Summary**: `docs/EMAIL_VERIFICATION_SETUP_SUMMARY.md`

## ✅ What's Already Done

- AndroidManifest.xml configured
- Deep link handler created
- PKCE flow enabled
- Auth repository updated with emailRedirectTo

## 🎉 Success = App opens from email link!
