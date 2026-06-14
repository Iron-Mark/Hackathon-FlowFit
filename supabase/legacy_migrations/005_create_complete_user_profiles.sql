-- Complete user_profiles table setup with all required columns
-- This migration can be used for fresh database setup or to verify existing structure

-- Drop existing table if recreating (use with caution in production)
-- DROP TABLE IF EXISTS user_profiles CASCADE;

-- Create user_profiles table with all required columns and constraints
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  age INTEGER CHECK (age >= 13 AND age <= 120),
  gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  height DECIMAL(5,2) CHECK (height > 0 AND height < 300),
  weight DECIMAL(5,2) CHECK (weight > 0 AND weight < 500),
  height_unit TEXT CHECK (height_unit IN ('cm', 'ft')) DEFAULT 'cm',
  weight_unit TEXT CHECK (weight_unit IN ('kg', 'lbs')) DEFAULT 'kg',
  activity_level TEXT CHECK (activity_level IN ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active')),
  goals TEXT[],
  daily_calorie_target INTEGER CHECK (daily_calorie_target > 0),
  daily_steps_target INTEGER CHECK (daily_steps_target > 0),
  daily_active_minutes_target INTEGER CHECK (daily_active_minutes_target > 0),
  daily_water_target DECIMAL(3,1) CHECK (daily_water_target > 0),
  profile_image_url TEXT,
  survey_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_created_at ON user_profiles(created_at);

-- Enable Row Level Security
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;

-- Policy: Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON user_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON user_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON user_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Create or replace function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;

-- Create trigger on user_profiles table
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add table and column comments for documentation
COMMENT ON TABLE user_profiles IS 'Stores user profile data collected during onboarding survey and editable in profile screen';
COMMENT ON COLUMN user_profiles.user_id IS 'Foreign key reference to auth.users table - unique per user';
COMMENT ON COLUMN user_profiles.full_name IS 'User full name';
COMMENT ON COLUMN user_profiles.age IS 'User age in years, must be between 13 and 120';
COMMENT ON COLUMN user_profiles.gender IS 'User gender: male, female, other, or prefer_not_to_say';
COMMENT ON COLUMN user_profiles.height IS 'User height in the unit specified by height_unit';
COMMENT ON COLUMN user_profiles.weight IS 'User weight in the unit specified by weight_unit';
COMMENT ON COLUMN user_profiles.height_unit IS 'Unit for height measurement: cm (centimeters) or ft (feet)';
COMMENT ON COLUMN user_profiles.weight_unit IS 'Unit for weight measurement: kg (kilograms) or lbs (pounds)';
COMMENT ON COLUMN user_profiles.activity_level IS 'User activity level: sedentary, lightly_active, moderately_active, very_active, or extremely_active';
COMMENT ON COLUMN user_profiles.goals IS 'Array of user fitness goals (e.g., lose_weight, build_muscle, improve_cardio)';
COMMENT ON COLUMN user_profiles.daily_calorie_target IS 'Calculated daily calorie target based on user profile';
COMMENT ON COLUMN user_profiles.daily_steps_target IS 'Daily step count goal';
COMMENT ON COLUMN user_profiles.daily_active_minutes_target IS 'Daily active minutes goal';
COMMENT ON COLUMN user_profiles.daily_water_target IS 'Daily water intake goal in liters';
COMMENT ON COLUMN user_profiles.profile_image_url IS 'URL to user profile image stored in Supabase Storage';
COMMENT ON COLUMN user_profiles.survey_completed IS 'Flag indicating whether user has completed the onboarding survey';
COMMENT ON COLUMN user_profiles.created_at IS 'Timestamp when profile was created';
COMMENT ON COLUMN user_profiles.updated_at IS 'Timestamp when profile was last updated (auto-updated by trigger)';
