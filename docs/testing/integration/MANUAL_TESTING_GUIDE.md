# Manual Testing Guide for Authentication and Onboarding

This guide provides step-by-step instructions for manually testing the complete authentication and onboarding flows in FlowFit.

## Prerequisites

1. **Supabase Setup**: Ensure Supabase is configured with correct URL and anon key in `lib/secrets.dart`
2. **Database Schema**: Verify `user_profiles` table exists with proper RLS policies
3. **Test Device**: Use a physical device or emulator with network connectivity
4. **Clean State**: Start with app uninstalled or data cleared for fresh testing

## Test Suite 1: Complete Signup Flow

**Requirements Tested**: 1.1, 3.1, 4.1, 4.5

### Test 1.1: Successful Signup → Survey → Dashboard

**Steps**:
1. Launch the app
2. Wait for splash screen to complete
3. Verify you land on the Welcome screen with "Find Your Flow" heading
4. Tap "Get Started" button
5. Verify navigation to Signup screen with "Create Your Account" heading

**Fill Signup Form**:
6. Enter Full Name: "Test User"
7. Enter Email: `test_${timestamp}@flowfit.test` (use unique email)
8. Enter Password: "TestPassword123!"
9. Enter Confirm Password: "TestPassword123!"
10. Check "I agree to FlowFit's Terms of Service and Privacy Policy"
11. Check "I consent to health data collection from my Galaxy Watch"
12. Optionally check "Send me tips & updates"

**Submit Signup**:
13. Tap "Create Account" button
14. Verify loading indicator appears
15. Wait for navigation (may take 2-3 seconds)

**Expected Result**: Navigate to Survey Intro screen with "Quick Setup" heading

**Survey Flow**:
16. Verify Survey Intro shows:
    - "Quick Setup (2 Minutes)" heading
    - "Let's personalize FlowFit for you, Test User!"
    - 4 progress dots
17. Tap "LET'S PERSONALIZE" button

**Basic Info Screen**:
18. Verify "Tell Us About You" heading
19. Enter Age: "30"
20. Select Gender: "Male"
21. Tap "NEXT" button

**Body Measurements Screen**:
22. Verify "Body Measurements" heading
23. Enter Weight: "75" kg
24. Enter Height: "175" cm
25. Tap "NEXT" button

**Activity Goals Screen**:
26. Verify "Activity & Goals" heading
27. Select Activity Level: "Moderately Active"
28. Select at least one goal: "Lose Weight"
29. Tap "NEXT" button

**Daily Targets Screen**:
30. Verify "Your Daily Targets" heading
31. Verify calculated calorie target is displayed
32. Verify summary of entered data
33. Tap "COMPLETE SETUP" button
34. Verify loading indicator appears

**Expected Result**: Navigate to Dashboard screen

**Verification**:
35. Open Supabase dashboard
36. Navigate to Table Editor → user_profiles
37. Verify new row exists with:
    - Correct user_id
    - full_name: "Test User"
    - age: 30
    - gender: "male"
    - weight: 75
    - height: 175
    - activity_level: "moderately_active"
    - goals: ["lose_weight"]
    - survey_completed: true
    - Timestamps populated

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 1.2: Signup with Duplicate Email

**Requirements Tested**: 1.2

**Prerequisites**: Create a user with email `existing@flowfit.test`

**Steps**:
1. Launch app and navigate to Signup screen
2. Enter Full Name: "Duplicate User"
3. Enter Email: "existing@flowfit.test"
4. Enter Password: "TestPassword123!"
5. Enter Confirm Password: "TestPassword123!"
6. Check required consents
7. Tap "Create Account"

**Expected Result**: 
- Error SnackBar appears at bottom of screen
- Message: "An account with this email already exists" (or similar)
- User remains on Signup screen
- No navigation occurs

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 1.3: Signup with Invalid Email Format

**Requirements Tested**: 1.3

**Steps**:
1. Navigate to Signup screen
2. Enter Full Name: "Test User"
3. Enter Email: "notanemail" (no @ symbol)
4. Enter Password: "TestPassword123!"
5. Enter Confirm Password: "TestPassword123!"
6. Check required consents
7. Tap "Create Account"

**Expected Result**:
- Validation error appears below email field
- Message: "Please enter a valid email"
- No API call made to Supabase (check network logs)
- User remains on Signup screen

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 1.4: Signup with Weak Password

**Requirements Tested**: 1.4

**Steps**:
1. Navigate to Signup screen
2. Enter Full Name: "Test User"
3. Enter Email: "test@flowfit.test"
4. Enter Password: "short" (less than 8 characters)
5. Enter Confirm Password: "short"
6. Check required consents
7. Tap "Create Account"

**Expected Result**:
- Validation error appears below password field
- Message: "Password must be at least 8 characters"
- No API call made to Supabase
- User remains on Signup screen

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 1.5: Signup without Required Consents

**Steps**:
1. Navigate to Signup screen
2. Fill in all form fields correctly
3. Do NOT check "Terms of Service" checkbox
4. Do NOT check "Watch data consent" checkbox
5. Tap "Create Account"

**Expected Result**:
- Error SnackBar appears
- Message: "Please accept required terms to continue"
- User remains on Signup screen

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

## Test Suite 2: Complete Login Flow

**Requirements Tested**: 2.1, 5.2, 5.3, 5.4

### Test 2.1: Login with Complete Profile → Dashboard

**Prerequisites**: Create user with completed profile:
- Email: `complete_user@flowfit.test`
- Password: `TestPassword123!`
- Profile: All survey fields completed

**Steps**:
1. Launch app (ensure logged out)
2. Wait for Welcome screen
3. Tap "Log In" link at bottom
4. Verify navigation to Login screen with "Welcome Back!" heading
5. Enter Email: "complete_user@flowfit.test"
6. Enter Password: "TestPassword123!"
7. Tap "Log In" button
8. Verify loading indicator appears

**Expected Result**:
- Navigate directly to Dashboard screen
- No survey screens shown
- User data loaded correctly

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 2.2: Login with Incomplete Profile → Survey

**Prerequisites**: Create user WITHOUT completed profile:
- Email: `incomplete_user@flowfit.test`
- Password: `TestPassword123!`
- Profile: No survey data

**Steps**:
1. Launch app (ensure logged out)
2. Navigate to Login screen
3. Enter Email: "incomplete_user@flowfit.test"
4. Enter Password: "TestPassword123!"
5. Tap "Log In" button

**Expected Result**:
- Navigate to Survey Intro screen
- "Quick Setup" heading displayed
- User can complete survey from here

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 2.3: Login with Invalid Credentials

**Requirements Tested**: 2.2

**Steps**:
1. Navigate to Login screen
2. Enter Email: "nonexistent@flowfit.test"
3. Enter Password: "WrongPassword123!"
4. Tap "Log In" button

**Expected Result**:
- Error SnackBar appears
- Message: "Invalid email or password" (or similar)
- User remains on Login screen
- No navigation occurs

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 2.4: Session Persistence Across App Restarts

**Requirements Tested**: 2.3, 5.1, 5.2

**Steps**:
1. Login successfully with valid credentials
2. Verify navigation to Dashboard
3. **Close app completely** (swipe away from recent apps)
4. Wait 5 seconds
5. **Reopen app**
6. Observe splash screen

**Expected Result**:
- Splash screen shows briefly
- App automatically navigates to Dashboard
- No Welcome screen shown
- No login required
- User data loaded correctly

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 2.5: Logout Clears Session

**Requirements Tested**: 2.5

**Steps**:
1. Login successfully
2. Navigate to Dashboard
3. Find and tap Logout button (location may vary)
4. Verify navigation to Welcome screen
5. **Close and reopen app**

**Expected Result**:
- After logout, Welcome screen is shown
- After app restart, Welcome screen is shown (not Dashboard)
- Session completely cleared
- Must login again to access app

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

## Test Suite 3: Social Sign-In Shortcuts

**Requirements Tested**: 6.1, 6.2, 6.3

### Test 3.1: Google Sign-In Button Navigation

**Steps**:
1. Navigate to Login screen
2. Locate "Sign in with Google" button
3. Verify button shows Google icon
4. Tap "Sign in with Google" button

**Expected Result**:
- Immediate navigation to Dashboard
- No authentication dialog shown
- No actual Google OAuth flow

**Verification**:
5. Open Supabase dashboard
6. Check Authentication → Users
7. Verify NO new user was created

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 3.2: Apple Sign-In Button Navigation

**Steps**:
1. Navigate to Login screen
2. Locate "Sign in with Apple" button
3. Verify button shows Apple icon
4. Tap "Sign in with Apple" button

**Expected Result**:
- Immediate navigation to Dashboard
- No authentication dialog shown
- No actual Apple OAuth flow

**Verification**:
5. Open Supabase dashboard
6. Check Authentication → Users
7. Verify NO new user was created

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 3.3: Social Sign-In No Auth Session

**Steps**:
1. Ensure logged out
2. Navigate to Login screen
3. Tap either Google or Apple sign-in button
4. Navigate to Dashboard
5. **Close and reopen app**

**Expected Result**:
- After app restart, Welcome screen is shown
- No persistent session created
- Must login again

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

## Test Suite 4: Survey Data Persistence

**Requirements Tested**: 3.2, 3.3, 3.4, 3.5

### Test 4.1: Partial Survey Data Persists

**Steps**:
1. Complete signup flow
2. On Survey Intro, tap "LET'S PERSONALIZE"
3. On Basic Info screen, enter:
   - Age: "25"
   - Gender: "Female"
4. Tap "NEXT"
5. On Body Measurements, enter:
   - Weight: "60"
   - Height: "165"
6. **Tap device back button** (or app back button)
7. Verify return to Basic Info screen
8. **Tap back again** to Survey Intro
9. Tap "I'll do this later →" to skip to Dashboard
10. **Close and reopen app**
11. Navigate back to survey (if prompted)

**Expected Result**:
- Previously entered data (age, gender, weight, height) is preserved
- Fields are pre-filled with entered values
- User can continue from where they left off

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 4.2: Survey Validation - Required Fields

**Requirements Tested**: 3.3

**Steps**:
1. Navigate to Basic Info screen
2. Leave Age field empty
3. Do NOT select gender
4. Tap "NEXT" button

**Expected Result**:
- Validation errors appear
- Cannot proceed to next screen
- Error messages indicate required fields

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 4.3: Survey Validation - Age Range

**Requirements Tested**: 3.4

**Test Invalid Ages**:
1. Enter Age: "12" → Tap NEXT
   - Expected: Validation error (minimum 13)
2. Enter Age: "121" → Tap NEXT
   - Expected: Validation error (maximum 120)
3. Enter Age: "30" → Tap NEXT
   - Expected: Success, proceed to next screen

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 4.4: Survey Validation - Weight/Height Range

**Requirements Tested**: 3.4

**Test Invalid Measurements**:
1. Enter Weight: "19" kg → Tap NEXT
   - Expected: Validation error (minimum 20)
2. Enter Weight: "501" kg → Tap NEXT
   - Expected: Validation error (maximum 500)
3. Enter Height: "49" cm → Tap NEXT
   - Expected: Validation error (minimum 50)
4. Enter Height: "301" cm → Tap NEXT
   - Expected: Validation error (maximum 300)
5. Enter valid values → Tap NEXT
   - Expected: Success

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 4.5: Survey Validation - Goals Selection

**Requirements Tested**: 3.5

**Steps**:
1. Navigate to Activity Goals screen
2. Select activity level: "Moderately Active"
3. Do NOT select any goals
4. Tap "NEXT" button

**Expected Result**:
- Validation error appears
- Message indicates at least one goal must be selected
- Cannot proceed

**Then**:
5. Select one goal: "Build Muscle"
6. Tap "NEXT"

**Expected Result**:
- Validation passes
- Proceed to Daily Targets screen

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

## Test Suite 5: Error Handling

**Requirements Tested**: 7.1, 7.2, 7.3, 7.5

### Test 5.1: Network Error Handling

**Steps**:
1. Navigate to Signup screen
2. Fill in all fields correctly
3. **Disable device network** (airplane mode or WiFi off)
4. Tap "Create Account"
5. Wait for timeout

**Expected Result**:
- User-friendly error message appears
- Message: "Network error. Please check your connection" (or similar)
- No technical details exposed
- User can retry after re-enabling network

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

### Test 5.2: Profile Save Retry Logic

**Requirements Tested**: 4.3

**Steps** (requires network simulation):
1. Complete signup and survey
2. Simulate intermittent network during profile save
3. Observe retry attempts

**Expected Result**:
- System retries up to 3 times
- Success after retry if network recovers
- Error message if all retries fail

**Status**: ✅ PASS / ❌ FAIL (or SKIP if cannot simulate)

**Notes**:
_______________________________________________________________________

---

### Test 5.3: Error Messages Don't Expose Technical Details

**Requirements Tested**: 7.5

**Steps**:
1. Trigger various errors (network, invalid credentials, etc.)
2. Examine all error messages shown to user

**Verify NO error messages contain**:
- Stack traces
- Database queries
- API keys
- Internal error codes
- File paths
- Technical jargon

**Verify error messages ARE**:
- User-friendly
- Actionable (tell user what to do)
- Clear and concise

**Status**: ✅ PASS / ❌ FAIL

**Notes**:
_______________________________________________________________________

---

## Test Summary

| Test Suite | Total Tests | Passed | Failed | Skipped |
|------------|-------------|--------|--------|---------|
| Signup Flow | 5 | | | |
| Login Flow | 5 | | | |
| Social Sign-In | 3 | | | |
| Survey Persistence | 5 | | | |
| Error Handling | 3 | | | |
| **TOTAL** | **21** | | | |

## Issues Found

| Test ID | Issue Description | Severity | Status |
|---------|-------------------|----------|--------|
| | | | |
| | | | |
| | | | |

## Test Environment

- **Date**: _______________
- **Tester**: _______________
- **Device**: _______________
- **OS Version**: _______________
- **App Version**: _______________
- **Supabase Project**: _______________

## Sign-Off

- [ ] All critical tests passed
- [ ] All issues documented
- [ ] Ready for production

**Tester Signature**: _______________ **Date**: _______________
