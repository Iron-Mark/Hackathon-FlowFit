-- Add missing columns to user_profiles table to support full profile functionality
-- This migration adds unit preferences, additional daily targets, and profile image support

-- Add unit preference columns
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS height_unit TEXT CHECK (height_unit IN ('cm', 'ft')) DEFAULT 'cm',
ADD COLUMN IF NOT EXISTS weight_unit TEXT CHECK (weight_unit IN ('kg', 'lbs')) DEFAULT 'kg';

-- Add additional daily target columns
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS daily_steps_target INTEGER CHECK (daily_steps_target > 0),
ADD COLUMN IF NOT EXISTS daily_active_minutes_target INTEGER CHECK (daily_active_minutes_target > 0),
ADD COLUMN IF NOT EXISTS daily_water_target DECIMAL(3,1) CHECK (daily_water_target > 0);

-- Add profile image URL column
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS profile_image_url TEXT;

-- Update column comments for documentation
COMMENT ON COLUMN user_profiles.height_unit IS 'Unit for height measurement: cm (centimeters) or ft (feet)';
COMMENT ON COLUMN user_profiles.weight_unit IS 'Unit for weight measurement: kg (kilograms) or lbs (pounds)';
COMMENT ON COLUMN user_profiles.daily_steps_target IS 'Daily step count goal';
COMMENT ON COLUMN user_profiles.daily_active_minutes_target IS 'Daily active minutes goal';
COMMENT ON COLUMN user_profiles.daily_water_target IS 'Daily water intake goal in liters';
COMMENT ON COLUMN user_profiles.profile_image_url IS 'URL to user profile image stored in Supabase Storage';

-- Make some existing NOT NULL constraints optional to match the design
-- (Users may not set all fields immediately)
ALTER TABLE user_profiles
ALTER COLUMN full_name DROP NOT NULL,
ALTER COLUMN age DROP NOT NULL,
ALTER COLUMN gender DROP NOT NULL,
ALTER COLUMN weight DROP NOT NULL,
ALTER COLUMN height DROP NOT NULL,
ALTER COLUMN activity_level DROP NOT NULL,
ALTER COLUMN goals DROP NOT NULL,
ALTER COLUMN daily_calorie_target DROP NOT NULL;
