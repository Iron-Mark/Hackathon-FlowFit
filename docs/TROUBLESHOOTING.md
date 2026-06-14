# Troubleshooting Guide

## Current Error: Table 'user_profiles' Not Found

### The Error You're Seeing

```
PostgrestException(message: Could not find the table 'public.user_profiles' in the schema cache, code: PGRST205, details: Not Found, hint: null)
```

### What This Means

The app is trying to save user profile data to a database table called `user_profiles`, but that table doesn't exist in your Supabase database yet.

### Quick Fix (5 Minutes)

**Follow this guide**: `supabase/SETUP_DATABASE.md`

Or follow these quick steps:

1. **Open Supabase Dashboard**
   - Go to https://supabase.com/dashboard
   - Select your project
   - Click **SQL Editor** in sidebar

2. **Run This SQL Script**
   ```sql
   -- Copy the entire combined migration from supabase/SETUP_DATABASE.md
   -- Or run the three migration files one by one
   ```

3. **Reload Schema Cache**
   - Go to Settings → API
   - Click "Reload schema cache"
   - Wait 10 seconds

4. **Test Your App**
   - Close app completely
   - Reopen and try signup again
   - Should work now! ✅

### Why This Happened

Task 8 in the implementation plan (Set up Supabase database schema) needs to be completed before the app can save user profiles. The migration files exist in `supabase/migrations/` but haven't been run on your Supabase instance yet.

---

## Other Common Issues

### Issue: "Invalid email or password" on login

**Cause**: User doesn't exist or wrong credentials

**Fix**: 
- Make sure you signed up first
- Check email spelling
- Check password (minimum 8 characters)
- Try "Forgot password" feature

---

### Issue: App crashes on startup

**Cause**: Supabase not initialized or wrong credentials

**Fix**:
1. Check `lib/secrets.dart` has correct URL and anon key
2. Verify Supabase project is active
3. Check network connection

---

### Issue: Survey data not saving

**Cause**: Either table doesn't exist OR RLS policies blocking access

**Fix**:
1. Run database setup scripts (see above)
2. Verify RLS policies are correct
3. Check user is authenticated before saving

---

### Issue: Session not persisting

**Cause**: SharedPreferences not working or session expired

**Fix**:
1. Clear app data and try again
2. Check if session token is valid
3. Verify Supabase session timeout settings

---

### Issue: "Network error" messages

**Cause**: No internet connection or Supabase down

**Fix**:
1. Check device internet connection
2. Try on WiFi instead of mobile data
3. Check Supabase status: https://status.supabase.com
4. Verify firewall not blocking Supabase

---

## Getting More Help

### Check Logs

Enable verbose logging to see detailed error messages:

```dart
// In lib/main.dart
void main() async {
  // Add this for debugging
  debugPrint('Starting FlowFit app...');
  
  // ... rest of main
}
```

### Check Supabase Dashboard

1. **Authentication → Users**: See if users are being created
2. **Table Editor → user_profiles**: See if data is being saved
3. **Logs → Postgres Logs**: See database errors
4. **Logs → API Logs**: See API request errors

### Test Supabase Connection

Run this test to verify Supabase is working:

```bash
flutter test test/supabase_connection_test.dart
```

---

## Documentation

- **Setup Guide**: `supabase/SETUP_DATABASE.md`
- **Manual Testing**: `test/integration/MANUAL_TESTING_GUIDE.md`
- **Quick Start**: `test/integration/QUICK_START.md`
- **Requirements**: `.kiro/specs/supabase-auth-onboarding/requirements.md`
- **Design**: `.kiro/specs/supabase-auth-onboarding/design.md`

---

## Contact

If you're still having issues after following this guide:

1. Check the task list: `.kiro/specs/supabase-auth-onboarding/tasks.md`
2. Review the design document for architecture details
3. Check if all previous tasks are completed
4. Verify Supabase project settings

---

## Quick Checklist

Before reporting an issue, verify:

- [ ] Supabase credentials in `lib/secrets.dart` are correct
- [ ] `user_profiles` table exists in Supabase
- [ ] RLS policies are configured
- [ ] Device has internet connection
- [ ] App has latest code changes
- [ ] Flutter dependencies are up to date (`flutter pub get`)
- [ ] No build errors (`flutter build apk --debug`)

---

## Status Check

Run these commands to verify your setup:

```bash
# Check Flutter version
flutter --version

# Check for build errors
flutter analyze

# Run tests
flutter test

# Check Supabase connection
flutter test test/supabase_connection_test.dart
```

---

## Summary

**Most Common Issue**: Database table not created  
**Solution**: Run SQL scripts in Supabase dashboard  
**Time to Fix**: 5 minutes  
**Success Rate**: 99% ✅

Follow `supabase/SETUP_DATABASE.md` for detailed instructions.
