# Database Migration Summary

## Task Completed: Set up Supabase database schema

All subtasks have been successfully completed for task 8 from the implementation plan.

## What Was Created

### Migration Files

1. **001_create_user_profiles_table.sql**
   - Creates the `user_profiles` table with all required columns
   - Adds CHECK constraints for data validation:
     - Age: 13-120 years
     - Gender: enum values (male, female, other, prefer_not_to_say)
     - Weight: 0-500 kg
     - Height: 0-300 cm
     - Activity level: enum values (sedentary, lightly_active, moderately_active, very_active, extremely_active)
     - Daily calorie target: > 0
   - Creates index on user_id for faster lookups
   - Adds documentation comments

2. **002_configure_rls_policies.sql**
   - Enables Row Level Security on user_profiles table
   - Creates three RLS policies:
     - "Users can view own profile" - SELECT policy
     - "Users can insert own profile" - INSERT policy
     - "Users can update own profile" - UPDATE policy
   - Adds documentation comments

3. **003_add_updated_at_trigger.sql**
   - Creates `update_updated_at_column()` function
   - Creates trigger `update_user_profiles_updated_at` on user_profiles table
   - Automatically updates the updated_at timestamp on any row update
   - Adds documentation comments

### Helper Files

4. **combined_migration.sql**
   - Single file containing all three migrations in the correct order
   - Convenient for one-step setup
   - Well-commented and organized

5. **README.md**
   - Comprehensive documentation of all migrations
   - Multiple application methods (Dashboard, CLI)
   - Database schema reference
   - Verification queries
   - Rollback instructions

6. **SETUP_INSTRUCTIONS.md**
   - Step-by-step guide for applying migrations
   - Verification steps
   - Testing examples
   - Troubleshooting section
   - Security notes

## Database Schema Overview

```
user_profiles
├── user_id (UUID, PRIMARY KEY, FK to auth.users)
├── full_name (TEXT, NOT NULL)
├── age (INTEGER, NOT NULL, CHECK 13-120)
├── gender (TEXT, NOT NULL, CHECK enum)
├── weight (DECIMAL(5,2), NOT NULL, CHECK 0-500)
├── height (DECIMAL(5,2), NOT NULL, CHECK 0-300)
├── activity_level (TEXT, NOT NULL, CHECK enum)
├── goals (TEXT[], NOT NULL)
├── daily_calorie_target (INTEGER, NOT NULL, CHECK > 0)
├── survey_completed (BOOLEAN, NOT NULL, DEFAULT false)
├── created_at (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())
└── updated_at (TIMESTAMPTZ, NOT NULL, DEFAULT NOW())

Indexes:
└── idx_user_profiles_user_id

RLS Policies:
├── Users can view own profile (SELECT)
├── Users can insert own profile (INSERT)
└── Users can update own profile (UPDATE)

Triggers:
└── update_user_profiles_updated_at (BEFORE UPDATE)
```

## How to Apply

### Quick Method (Recommended)

1. Open Supabase Dashboard → SQL Editor
2. Copy contents of `combined_migration.sql`
3. Paste and run
4. Done! ✅

### Detailed Instructions

See `SETUP_INSTRUCTIONS.md` for:
- Step-by-step guide
- Verification queries
- Testing examples
- Troubleshooting tips

## Requirements Validated

This implementation satisfies **Requirement 4.1** from the requirements document:

> "WHEN a user completes the entire survey THEN the Auth System SHALL save all survey data to the User Profile in Supabase"

The database schema provides:
- ✅ Proper data types and constraints for all survey fields
- ✅ Row Level Security to protect user data
- ✅ Automatic timestamp management
- ✅ Foreign key relationship to auth.users
- ✅ Data validation at the database level

## Next Steps

After applying these migrations:

1. The database is ready to receive user profile data
2. The ProfileRepository implementation (already completed in task 3.5) can now interact with this table
3. Users can complete the survey and their data will be securely stored
4. The app can query profile completion status to route users appropriately

## Security Features

- **Row Level Security**: Users can only access their own data
- **CHECK Constraints**: Invalid data is rejected at the database level
- **Foreign Key Cascade**: Profile data is automatically deleted when user account is deleted
- **Timestamp Tracking**: Automatic created_at and updated_at timestamps
- **Policy-Based Access**: Fine-grained control over SELECT, INSERT, and UPDATE operations

## Testing

The migrations include comprehensive constraints that will:
- Reject ages outside 13-120 range
- Reject invalid gender values
- Reject weights outside 0-500 kg range
- Reject heights outside 0-300 cm range
- Reject invalid activity levels
- Reject non-positive calorie targets
- Prevent users from accessing other users' data

All of these validations happen at the database level, providing a strong security boundary.
