# Quick Start Guide - Integration Testing

## For QA Testers (Manual Testing)

### What You Need
- FlowFit app installed on Android device or emulator
- Access to Supabase dashboard
- This testing guide

### How to Test

1. **Open the Manual Testing Guide**
   - File: `docs/testing/integration/MANUAL_TESTING_GUIDE.md`
   - Print it or open on second screen

2. **Start with Test Suite 1: Complete Signup Flow**
   - Follow each step exactly as written
   - Mark ✅ PASS or ❌ FAIL for each test
   - Add notes about any issues

3. **Continue with Other Test Suites**
   - Test Suite 2: Complete Login Flow
   - Test Suite 3: Social OAuth Availability
   - Test Suite 4: Survey Data Persistence
   - Test Suite 5: Error Handling

4. **Document Issues**
   - Use the "Issues Found" table at the end
   - Include test ID, description, and severity

5. **Sign Off**
   - Complete the sign-off section when done
   - Share results with development team

### Time Estimate
- Complete testing: 1-2 hours
- Quick smoke test: 20-30 minutes (Test Suites 1-3 only)

---

## For Developers (Automated Testing)

### Prerequisites

```bash
# Ensure Flutter is installed
flutter --version

# Ensure dependencies are installed
flutter pub get
```

### Running Tests

#### Run All Integration Tests
```bash
flutter test test/integration/
```

#### Run Specific Test File
```bash
flutter test test/integration/auth_flow_test.dart
flutter test test/integration/login_flow_test.dart
```

#### Run with Verbose Output
```bash
flutter test test/integration/ --verbose
```

### Important Notes

⚠️ **Platform Dependencies**: Some tests require platform-specific plugins and are marked with `skip: true`. These tests need to run on actual devices or emulators, not in pure Dart VM.

⚠️ **Test Data**: Tests that create real users require unique email addresses. Use timestamp-based emails or clean up after each run.

⚠️ **Network Required**: Tests interact with real Supabase instance and require network connectivity.

### Test Setup (For Unskipped Tests)

1. **Create Test Users in Supabase**:
   - `complete_user@flowfit.test` with completed profile
   - `incomplete_user@flowfit.test` without profile
   - `existing@flowfit.test` for duplicate email test

2. **Enable Tests**:
   - Remove `skip: true` from relevant tests
   - Update test user credentials if needed

3. **Run Tests**:
   ```bash
   flutter test test/integration/ --no-skip
   ```

### Cleanup Test Data

After testing, clean up test users:

```sql
-- Run in Supabase SQL Editor
DELETE FROM auth.users WHERE email LIKE '%@flowfit.test';
DELETE FROM user_profiles WHERE user_id IN (
  SELECT id FROM auth.users WHERE email LIKE '%@flowfit.test'
);
```

---

## For CI/CD Pipeline

### Setup

1. **Configure Supabase Test Instance**
   ```bash
   export SUPABASE_URL="https://PROJECT_REF.supabase.co"
   export SUPABASE_PUBLISHABLE_KEY="REPLACE_WITH_SUPABASE_PUBLISHABLE_KEY"
   ```

2. **Create Test Users** (via migration script)
   ```bash
   ./scripts/create_test_users.sh
   ```

3. **Run Tests**
   ```bash
   flutter test test/integration/ --coverage
   ```

4. **Generate Coverage Report**
   ```bash
   genhtml coverage/lcov.info -o coverage/html
   ```

5. **Cleanup**
   ```bash
   ./scripts/cleanup_test_users.sh
   ```

---

## Quick Smoke Test (5 minutes)

For rapid verification, run these critical tests manually:

1. **Signup Flow** (2 min)
   - Create account → Complete survey → Reach dashboard

2. **Login Flow** (1 min)
   - Login with valid credentials → Reach dashboard

3. **Social OAuth Guard** (1 min)
   - Confirm Google/Apple sign-in buttons are not shown
   - Confirm dashboard is reachable only through real login or restored session

4. **Session Persistence** (1 min)
   - Close and reopen app → Auto-login to dashboard

If all pass: ✅ Core functionality working

If any fail: ❌ Review detailed test guide and investigate

---

## Getting Help

### Documentation
- **Detailed Manual Tests**: `MANUAL_TESTING_GUIDE.md`
- **Test Documentation**: `README.md`
- **Implementation Summary**: `TESTING_SUMMARY.md`

### Common Issues

**Q: Tests fail with "Supabase not initialized"**
A: Ensure `setUpAll()` initializes Supabase before tests run

**Q: Tests timeout**
A: Increase timeout: `timeout: const Timeout(Duration(minutes: 2))`

**Q: Widget not found**
A: Use `pumpAndSettle()` with longer duration for async operations

**Q: Platform plugin errors**
A: Run tests on actual device/emulator, not in Dart VM

### Contact
- Check task documentation: `.kiro/specs/supabase-auth-onboarding/`
- Review requirements: `requirements.md`
- Review design: `design.md`
- Review tasks: `tasks.md`

---

## Test Status Dashboard

| Component | Automated | Manual | Status |
|-----------|-----------|--------|--------|
| Signup Flow | ✅ | ✅ | Ready |
| Login Flow | ⚠️ Partial | ✅ | Ready |
| Social OAuth Guard | ✅ | ✅ | Ready |
| Survey Persistence | ❌ | ✅ | Manual Only |
| Error Handling | ❌ | ✅ | Manual Only |

Legend:
- ✅ Fully implemented
- ⚠️ Partially implemented
- ❌ Manual coverage only

---

## Next Steps

1. ✅ Integration tests created
2. ✅ Manual testing guide created
3. ✅ Documentation complete
4. ⏭️ Execute manual tests
5. ⏭️ Fix any issues found
6. ⏭️ Sign off on testing
7. ⏭️ Deploy to production

**Current Status**: Ready for manual testing execution
