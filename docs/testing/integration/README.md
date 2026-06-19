# Integration Testing Guide

This directory contains integration tests for the FlowFit authentication and onboarding flows.

## Overview

The integration tests verify the complete user experience for:

1. **Signup Flow** (Requirements 1.1, 3.1, 4.1, 4.5)
   - Complete signup → survey → dashboard flow
   - Duplicate email handling
   - Invalid email validation
   - Data persistence to Supabase

2. **Login Flow** (Requirements 2.1, 5.2, 5.3, 5.4)
   - Login → dashboard for users with complete profiles
   - Login → survey for users with incomplete profiles
   - Session persistence across app restarts
   - Invalid credentials handling

3. **Social Sign-In Shortcuts** (Requirements 6.1, 6.2, 6.3)
   - Google Sign-In button navigation
   - Apple Sign-In button navigation
   - Verification that no auth session is created

## Running the Tests

### Run All Integration Tests

```bash
flutter test test/integration/
```

### Run Specific Test File

```bash
flutter test test/integration/auth_flow_test.dart
flutter test test/integration/login_flow_test.dart
```

### Run with Verbose Output

```bash
flutter test test/integration/ --verbose
```

## Test Setup Requirements

Some tests are marked with `skip: true` because they require manual setup:

### 1. Create Test Users

Before running the full test suite, create these test users in Supabase:

#### User with Complete Profile
- Email: `complete_user@flowfit.test`
- Password: `TestPassword123!`
- Profile: Complete all survey fields

#### User with Incomplete Profile
- Email: `incomplete_user@flowfit.test`
- Password: `TestPassword123!`
- Profile: Do NOT complete survey

#### User for Session Testing
- Email: `session_test@flowfit.test`
- Password: `TestPassword123!`
- Profile: Complete all survey fields

#### Existing User for Duplicate Email Test
- Email: `existing@flowfit.test`
- Password: `TestPassword123!`

### 2. Enable Tests

Once test users are created, remove the `skip: true` flag from the relevant tests in:
- `auth_flow_test.dart`
- `login_flow_test.dart`

## Manual Testing Checklist

While automated tests cover most scenarios, some aspects require manual verification:

### Signup Flow Manual Tests

- [ ] **Valid Signup**
  1. Open app → Welcome screen
  2. Tap "Get Started"
  3. Fill in all fields with valid data
  4. Accept required consents
  5. Tap "Create Account"
  6. Verify navigation to Survey Intro
  7. Complete all survey steps
  8. Verify navigation to Dashboard
  9. Check Supabase database for saved profile data

- [ ] **Duplicate Email**
  1. Try to sign up with an existing email
  2. Verify error message: "An account with this email already exists"

- [ ] **Invalid Email**
  1. Enter email without @ symbol
  2. Verify validation error before API call

- [ ] **Weak Password**
  1. Enter password with less than 8 characters
  2. Verify validation error

- [ ] **Missing Consents**
  1. Try to submit without checking required consents
  2. Verify error message

### Login Flow Manual Tests

- [ ] **Valid Login - Complete Profile**
  1. Open app → Welcome screen
  2. Tap "Log In"
  3. Enter valid credentials for user with complete profile
  4. Tap "Log In"
  5. Verify navigation directly to Dashboard

- [ ] **Valid Login - Incomplete Profile**
  1. Log in with user who hasn't completed survey
  2. Verify navigation to Survey Intro

- [ ] **Invalid Credentials**
  1. Enter wrong password
  2. Verify error message: "Invalid email or password"

- [ ] **Session Persistence**
  1. Log in successfully
  2. Close app completely
  3. Reopen app
  4. Verify automatic login (no welcome screen)
  5. Verify navigation to correct screen based on profile status

- [ ] **Logout**
  1. Log in successfully
  2. Navigate to profile/settings
  3. Tap logout
  4. Verify navigation to Welcome screen
  5. Reopen app
  6. Verify Welcome screen shows (session cleared)

### Social Sign-In Manual Tests

- [ ] **Google Sign-In Button**
  1. Navigate to Login screen
  2. Tap "Sign in with Google"
  3. Verify immediate navigation to Dashboard
  4. Verify no auth session created (check Supabase)

- [ ] **Apple Sign-In Button**
  1. Navigate to Login screen
  2. Tap "Sign in with Apple"
  3. Verify immediate navigation to Dashboard
  4. Verify no auth session created

### Survey Flow Manual Tests

- [ ] **Survey Data Persistence**
  1. Start survey
  2. Fill in Basic Info
  3. Navigate away (back button)
  4. Return to survey
  5. Verify data is preserved

- [ ] **Survey Validation**
  1. Try to proceed with empty required fields
  2. Verify validation errors
  3. Try invalid age (e.g., 6, 121)
  4. Verify range validation
  5. Try invalid weight/height
  6. Verify range validation

- [ ] **Survey Completion**
  1. Complete all survey steps
  2. Tap "COMPLETE SETUP"
  3. Verify data saved to Supabase
  4. Verify navigation to Dashboard

### Error Handling Manual Tests

- [ ] **Network Errors**
  1. Disable network connection
  2. Try to sign up
  3. Verify user-friendly error message
  4. Re-enable network
  5. Retry and verify success

- [ ] **Supabase Errors**
  1. Check logs for any Supabase errors
  2. Verify errors are logged with context
  3. Verify user sees friendly message (not technical details)

- [ ] **Retry Logic**
  1. Simulate network instability during profile save
  2. Verify retry attempts (up to 3)
  3. Verify success after retry

## Test Data Cleanup

After running tests, clean up test data:

```sql
-- Delete test users from Supabase
DELETE FROM auth.users WHERE email LIKE '%@flowfit.test';
DELETE FROM user_profiles WHERE user_id IN (
  SELECT id FROM auth.users WHERE email LIKE '%@flowfit.test'
);
```

## Troubleshooting

### Tests Fail with "Supabase not initialized"

Ensure `setUpAll()` is called before tests run:

```dart
setUpAll(() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseRuntimeConfig.url,
    anonKey: SupabaseRuntimeConfig.publishableKey,
  );
});
```

### Tests Timeout

Increase timeout for integration tests:

```dart
testWidgets(
  'test name',
  (tester) async {
    // test code
  },
  timeout: const Timeout(Duration(minutes: 2)),
);
```

### Widget Not Found

Use `pumpAndSettle()` with longer duration for async operations:

```dart
await tester.pumpAndSettle(const Duration(seconds: 3));
```

## CI/CD Integration

To run these tests in CI/CD:

1. Set up Supabase test instance
2. Create test users via migration script
3. Run tests with environment variables:

```bash
export SUPABASE_URL="https://PROJECT_REF.supabase.co"
export SUPABASE_PUBLISHABLE_KEY="REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY"
flutter test test/integration/
```

## Coverage

To generate coverage report:

```bash
flutter test --coverage test/integration/
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Related Documentation

- [Requirements Document](../../../.kiro/specs/supabase-auth-onboarding/requirements.md)
- [Design Document](../../../.kiro/specs/supabase-auth-onboarding/design.md)
- [Task List](../../../.kiro/specs/supabase-auth-onboarding/tasks.md)
