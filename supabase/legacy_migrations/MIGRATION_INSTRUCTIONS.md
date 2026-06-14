# User Profiles Table Migration Instructions

## Overview

This document explains the migration files created for the `user_profiles` table and how to apply them to your Supabase database.

## Migration Files

### Existing Migrations (Already Applied)

1. **001_create_user_profiles_table.sql**

   - Creates the basic user_profiles table
   - Adds core columns: user_id, full_name, age, gender, weight, height, activity_level, goals, daily_calorie_target
   - Sets up indexes and constraints

2. **002_configure_rls_policies.sql**

   - Enables Row Level Security (RLS)
   - Creates policies for SELECT, INSERT, UPDATE operations
   - Ensures users can only access their own data

3. **003_add_updated_at_trigger.sql**
   - Creates trigger function to auto-update `updated_at` timestamp
   - Applies trigger to user_profiles table

### New Migrations (To Be Applied)

4. **004_add_missing_profile_columns.sql**

   - Adds missing columns required by the design:
     - `height_unit` (cm|ft)
     - `weight_unit` (kg|lbs)
     - `daily_steps_target`
     - `daily_active_minutes_target`
     - `daily_water_target`
     - `profile_image_url`
   - Makes some NOT NULL constraints optional for flexibility
   - Adds column comments for documentation

5. **005_create_complete_user_profiles.sql**
   - Complete table definition with all columns
   - Can be used for fresh database setup
   - Includes all RLS policies and triggers
   - Useful as reference or for new environments

### Testing Files

6. **test_rls_policies.sql**

   - SQL test script for constraint validation
   - Tests age, gender, activity_level, and unit constraints
   - Provides framework for RLS testing

7. **RLS_TESTING_GUIDE.md**
   - Comprehensive guide for testing RLS policies
   - Step-by-step test scenarios
   - Example code for automated testing
   - Troubleshooting tips

## How to Apply Migrations

### Option 1: Via Supabase Dashboard (Recommended)

1. Open your Supabase project dashboard
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy the contents of `004_add_missing_profile_columns.sql`
5. Paste into the SQL Editor
6. Click **Run** to execute
7. Verify success in the output panel

### Option 2: Via Supabase CLI

```bash
# Navigate to your project root
cd /path/to/your/project

# Apply the migration
supabase db push

# Or apply specific migration file
psql -h <your-db-host> -U postgres -d postgres -f supabase/migrations/004_add_missing_profile_columns.sql
```

### Option 3: Via psql Command Line

```bash
# Connect to your Supabase database
psql "postgresql://postgres:[YOUR-PASSWORD]@[YOUR-PROJECT-REF].supabase.co:5432/postgres"

# Run the migration
\i supabase/migrations/004_add_missing_profile_columns.sql

# Verify the changes
\d user_profiles
```

## Verification Steps

After applying the migrations, verify the changes:

### 1. Check Table Structure

```sql
-- View all columns
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'user_profiles'
ORDER BY ordinal_position;
```

Expected columns:

- id (uuid)
- user_id (uuid)
- full_name (text)
- age (integer)
- gender (text)
- height (numeric)
- weight (numeric)
- height_unit (text) ← NEW
- weight_unit (text) ← NEW
- activity_level (text)
- goals (text[])
- daily_calorie_target (integer)
- daily_steps_target (integer) ← NEW
- daily_active_minutes_target (integer) ← NEW
- daily_water_target (numeric) ← NEW
- profile_image_url (text) ← NEW
- survey_completed (boolean)
- created_at (timestamptz)
- updated_at (timestamptz)

### 2. Check Constraints

```sql
-- View all constraints
SELECT conname, contype, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'user_profiles'::regclass;
```

Expected constraints:

- Age: 13-120
- Gender: male, female, other, prefer_not_to_say
- Activity level: sedentary, lightly_active, moderately_active, very_active, extremely_active
- Height unit: cm, ft
- Weight unit: kg, lbs
- Positive values for height, weight, targets

### 3. Check RLS Policies

```sql
-- View RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'user_profiles';
```

Expected policies:

- Users can view own profile (SELECT)
- Users can insert own profile (INSERT)
- Users can update own profile (UPDATE)

### 4. Check Trigger

```sql
-- View triggers
SELECT trigger_name, event_manipulation, event_object_table, action_statement
FROM information_schema.triggers
WHERE event_object_table = 'user_profiles';
```

Expected trigger:

- update_user_profiles_updated_at (BEFORE UPDATE)

## Testing the Migration

### Quick Test

```sql
-- Test insert with new columns
INSERT INTO user_profiles (
  user_id,
  full_name,
  age,
  gender,
  height,
  weight,
  height_unit,
  weight_unit,
  activity_level,
  goals,
  daily_calorie_target,
  daily_steps_target,
  daily_active_minutes_target,
  daily_water_target
) VALUES (
  uuid_generate_v4(),
  'Test User',
  25,
  'male',
  175.5,
  70.0,
  'cm',
  'kg',
  'moderately_active',
  ARRAY['lose_weight', 'improve_cardio'],
  2000,
  10000,
  30,
  2.5
);

-- Verify insert
SELECT * FROM user_profiles WHERE full_name = 'Test User';

-- Clean up test data
DELETE FROM user_profiles WHERE full_name = 'Test User';
```

### Comprehensive Testing

Follow the steps in `RLS_TESTING_GUIDE.md` for complete RLS policy testing.

## Rollback Instructions

If you need to rollback the migration:

```sql
-- Remove new columns
ALTER TABLE user_profiles
DROP COLUMN IF EXISTS height_unit,
DROP COLUMN IF EXISTS weight_unit,
DROP COLUMN IF EXISTS daily_steps_target,
DROP COLUMN IF EXISTS daily_active_minutes_target,
DROP COLUMN IF EXISTS daily_water_target,
DROP COLUMN IF EXISTS profile_image_url;

-- Restore NOT NULL constraints (if needed)
ALTER TABLE user_profiles
ALTER COLUMN full_name SET NOT NULL,
ALTER COLUMN age SET NOT NULL,
ALTER COLUMN gender SET NOT NULL,
ALTER COLUMN weight SET NOT NULL,
ALTER COLUMN height SET NOT NULL,
ALTER COLUMN activity_level SET NOT NULL,
ALTER COLUMN goals SET NOT NULL,
ALTER COLUMN daily_calorie_target SET NOT NULL;
```

## Common Issues and Solutions

### Issue: Migration fails with "column already exists"

**Solution**: The column was already added. You can either:

1. Skip this migration
2. Use `ADD COLUMN IF NOT EXISTS` (already included in migration)

### Issue: RLS policies prevent admin access

**Solution**: Use service role key for admin operations:

```dart
final supabase = SupabaseClient(
  'YOUR_URL',
  'YOUR_SERVICE_ROLE_KEY', // Not anon key
);
```

### Issue: Constraints too restrictive

**Solution**: Modify constraints in migration file before applying:

```sql
-- Example: Allow wider age range
ALTER TABLE user_profiles
DROP CONSTRAINT IF EXISTS user_profiles_age_check,
ADD CONSTRAINT user_profiles_age_check CHECK (age >= 10 AND age <= 150);
```

## Next Steps

1. ✅ Apply migration 004 to add missing columns
2. ✅ Verify table structure matches design
3. ✅ Test RLS policies using the testing guide
4. ✅ Update Flutter app to use new columns
5. ✅ Test end-to-end flow: onboarding → profile → edit

## Support

For issues or questions:

- Check Supabase logs in Dashboard → Database → Logs
- Review PostgreSQL error messages
- Consult `RLS_TESTING_GUIDE.md` for testing help
- Check Supabase documentation: https://supabase.com/docs
