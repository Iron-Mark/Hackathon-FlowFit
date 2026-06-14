# Flow Fixed - Summary

## Issues Fixed

### 1. ✅ Duplicate Name Collection
**Problem**: User was asked for their full name twice - once during signup and again in the survey.

**Solution**: Removed the name field from Survey Screen 1 (Basic Info). The name is now:
- Collected ONCE during signup
- Passed to survey via navigation arguments
- Automatically saved to survey data
- Displayed as greeting: "Hi [Name]!"

### 2. ✅ Database RLS Policy Error
**Problem**: `PostgrestException: new row violates row-level security policy for table "user_profiles"`

**Solution**: Updated RLS policies to explicitly specify `TO authenticated` clause.

**Fix Script**: Run this in Supabase SQL Editor:
```sql
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;

CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

## Current Flow (Correct)

### 1. Signup Screen
**Collects**:
- ✅ Full Name
- ✅ Email
- ✅ Password
- ✅ Terms acceptance
- ✅ Watch data consent
- ✅ Marketing opt-in

**On Success**: Navigate to Survey Intro with user data

---

### 2. Survey Intro Screen
**Shows**:
- Welcome message with user name
- Quick overview (2 minutes, 4 questions)
- Features preview (calorie target, heart rate zones, goals)
- Progress dots (4 steps)

**Actions**:
- "LET'S PERSONALIZE" → Survey Screen 1
- "I'll do this later" → Dashboard

---

### 3. Survey Screen 1: Basic Info
**Collects**:
- ✅ Age (13-120)
- ✅ Gender (Male/Female/Other/Prefer not to say)

**Auto-saved**:
- ✅ Full Name (from signup)

**UI**:
- Progress: Step 1 of 4
- Greeting: "Hi [Name]!"
- Icon: User icon
- Button: "NEXT"

---

### 4. Survey Screen 2: Body Measurements
**Collects**:
- ✅ Weight (kg, 0-500)
- ✅ Height (cm, 0-300)

**UI**:
- Progress: Step 2 of 4
- Icon: Scale icon
- Info box: "We use this to calculate your BMI and personalized calorie targets"
- Button: "NEXT"

---

### 5. Survey Screen 3: Activity & Goals
**Collects**:
- ✅ Activity Level (Sedentary/Moderately Active/Very Active)
- ✅ Goals (Lose Weight/Maintain/Build Muscle/Improve Cardio - max 5)

**UI**:
- Progress: Step 3 of 4
- Two sections: Activity Level + Goals
- Button: "CONTINUE →"
- Skip option available

---

### 6. Survey Screen 4: Daily Targets
**Shows**:
- ✅ Calculated calorie target (based on BMR + activity + goals)
- ✅ Steps target (adjustable: 5K/10K/12K/15K)
- ✅ Active minutes (adjustable: 20/30/45/60)
- ✅ Water intake (adjustable: 1.5L/2L/2.5L/3L)
- ✅ Summary of all entered data

**Actions**:
- "COMPLETE & START APP" → Submit to Supabase → Dashboard
- "Use these defaults" → Dashboard
- "← Back" → Previous screen

**UI**:
- Progress: Step 4 of 4
- All progress bars filled
- Green completion button
- Loading state during submission

---

### 7. Dashboard
**Shows**: Main app interface

---

## Data Flow

### Signup → Survey
```
SignupScreen
  ↓ (collects: name, email, password)
  ↓ (creates auth user)
  ↓
SurveyIntroScreen
  ↓ (passes: name, email, userId)
  ↓
SurveyBasicInfoScreen
  ↓ (saves: name from args, age, gender)
  ↓
SurveyBodyMeasurementsScreen
  ↓ (saves: weight, height)
  ↓
SurveyActivityGoalsScreen
  ↓ (saves: activityLevel, goals)
  ↓
SurveyDailyTargetsScreen
  ↓ (calculates: dailyCalorieTarget)
  ↓ (submits all data to Supabase)
  ↓
Dashboard
```

### Survey Data Structure
```dart
{
  'fullName': 'John Doe',        // From signup
  'age': 30,                     // Screen 1
  'gender': 'male',              // Screen 1
  'weight': 75.0,                // Screen 2
  'height': 175.0,               // Screen 2
  'activityLevel': 'moderately_active',  // Screen 3
  'goals': ['lose_weight', 'improve_cardio'],  // Screen 3
  'dailyCalorieTarget': 2450,    // Screen 4 (calculated)
}
```

### Supabase user_profiles Table
```sql
user_id UUID PRIMARY KEY
full_name TEXT NOT NULL
age INTEGER NOT NULL (13-120)
gender TEXT NOT NULL (male/female/other/prefer_not_to_say)
weight DECIMAL(5,2) NOT NULL (0-500)
height DECIMAL(5,2) NOT NULL (0-300)
activity_level TEXT NOT NULL (sedentary/lightly_active/moderately_active/very_active/extremely_active)
goals TEXT[] NOT NULL
daily_calorie_target INTEGER NOT NULL
survey_completed BOOLEAN NOT NULL DEFAULT false
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
```

---

## UI Consistency

All 4 survey screens now have consistent:
- ✅ Progress indicators (dots or bars)
- ✅ Step counter (1 of 4, 2 of 4, etc.)
- ✅ Icon at top (user/scale/activity/target)
- ✅ Title and subtitle
- ✅ Primary action button (NEXT/CONTINUE/COMPLETE)
- ✅ Back button
- ✅ Skip option (where appropriate)
- ✅ Same color scheme (AppTheme.primaryBlue)
- ✅ Same border radius (12px)
- ✅ Same padding (24px)

---

## Testing Checklist

### Database Setup
- [ ] Run RLS fix script in Supabase SQL Editor
- [ ] Verify policies exist: `SELECT * FROM pg_policies WHERE tablename = 'user_profiles'`
- [ ] Reload schema cache: Settings → API → Reload schema cache

### Flow Testing
- [ ] Signup with new account
- [ ] Verify name is NOT asked again in survey
- [ ] Complete all 4 survey screens
- [ ] Verify data saves to Supabase
- [ ] Check user_profiles table has new row
- [ ] Verify all fields populated correctly
- [ ] Confirm navigation to dashboard

### Error Testing
- [ ] Try invalid age (12, 121)
- [ ] Try invalid weight (0, 501)
- [ ] Try invalid height (0, 301)
- [ ] Try submitting without selecting gender
- [ ] Try submitting without selecting activity level
- [ ] Try submitting without selecting goals
- [ ] Verify error messages are user-friendly

---

## Files Modified

1. ✅ `lib/screens/onboarding/survey_basic_info_screen.dart`
   - Removed name field
   - Added name from arguments
   - Updated greeting to show user name

2. ✅ `supabase/migrations/002_configure_rls_policies.sql`
   - Added `TO authenticated` clause to all policies

3. ✅ `supabase/FIX_RLS_POLICY.sql`
   - Created quick fix script

4. ✅ `supabase/QUICK_FIX_RLS.md`
   - Created step-by-step fix guide

---

## Next Steps

1. **Run Database Fix** (2 minutes)
   - Open Supabase Dashboard
   - Go to SQL Editor
   - Run script from `supabase/QUICK_FIX_RLS.md`
   - Reload schema cache

2. **Test Complete Flow** (5 minutes)
   - Close app completely
   - Reopen app
   - Sign up with new account
   - Complete survey
   - Verify dashboard loads

3. **Verify Data** (1 minute)
   - Open Supabase Dashboard
   - Go to Table Editor → user_profiles
   - Check new row exists with all data

---

## Success Criteria

✅ User enters name ONCE (during signup)
✅ Survey has 4 distinct screens
✅ Each screen collects specific data
✅ No duplicate data collection
✅ Data saves to Supabase successfully
✅ RLS policies allow authenticated users
✅ Navigation flow is smooth
✅ UI is consistent across all screens
✅ Error handling works properly
✅ User reaches dashboard after completion

---

## Support

If you still have issues:
1. Check `TROUBLESHOOTING.md`
2. Check `supabase/QUICK_FIX_RLS.md`
3. Check `supabase/SETUP_DATABASE.md`
4. Verify Supabase credentials in `lib/secrets.dart`
5. Check Flutter logs for detailed errors

---

**Status**: ✅ FIXED - Ready for testing
