-- ============================================================================
-- FlowFit User Profiles Database Schema
-- Combined Migration File
-- ============================================================================
-- This file contains all migrations for setting up the user_profiles table
-- with proper constraints, indexes, Row Level Security, and triggers.
-- ============================================================================

-- ============================================================================
-- STEP 1: Create user_profiles table
-- ============================================================================

-- Create user_profiles table with all required columns and constraints
CREATE TABLE user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  age INTEGER NOT NULL CHECK (age >= 13 AND age <= 120),
  gender TEXT NOT NULL CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  weight DECIMAL(5,2) NOT NULL CHECK (weight > 0 AND weight < 500),
  height DECIMAL(5,2) NOT NULL CHECK (height > 0 AND height < 300),
  activity_level TEXT NOT NULL CHECK (activity_level IN ('sedentary', 'lightly_active', 'moderately_active', 'very_active', 'extremely_active')),
  goals TEXT[] NOT NULL,
  daily_calorie_target INTEGER NOT NULL CHECK (daily_calorie_target > 0),
  survey_completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index on user_id for faster lookups
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);

-- Add comment to table
COMMENT ON TABLE user_profiles IS 'Stores user profile data collected during onboarding survey';

-- Add comments to columns for documentation
COMMENT ON COLUMN user_profiles.user_id IS 'Foreign key reference to auth.users table';
COMMENT ON COLUMN user_profiles.age IS 'User age in years, must be between 13 and 120';
COMMENT ON COLUMN user_profiles.weight IS 'User weight in kilograms, must be between 0 and 500';
COMMENT ON COLUMN user_profiles.height IS 'User height in centimeters, must be between 0 and 300';
COMMENT ON COLUMN user_profiles.activity_level IS 'User activity level: sedentary, lightly_active, moderately_active, very_active, or extremely_active';
COMMENT ON COLUMN user_profiles.goals IS 'Array of user fitness goals';
COMMENT ON COLUMN user_profiles.daily_calorie_target IS 'Calculated daily calorie target based on user profile';
COMMENT ON COLUMN user_profiles.survey_completed IS 'Flag indicating whether user has completed the onboarding survey';

-- ============================================================================
-- STEP 2: Configure Row Level Security
-- ============================================================================

-- Enable Row Level Security on user_profiles table
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON user_profiles
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own profile
CREATE POLICY "Users can insert own profile"
  ON user_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON user_profiles
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Add comments to policies for documentation
COMMENT ON POLICY "Users can view own profile" ON user_profiles IS 'Allows users to read only their own profile data';
COMMENT ON POLICY "Users can insert own profile" ON user_profiles IS 'Allows users to create only their own profile record';
COMMENT ON POLICY "Users can update own profile" ON user_profiles IS 'Allows users to update only their own profile data';

-- ============================================================================
-- STEP 3: Add updated_at trigger
-- ============================================================================

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on user_profiles table to call the function before updates
CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON FUNCTION update_updated_at_column() IS 'Automatically updates the updated_at timestamp to current time on row updates';
COMMENT ON TRIGGER update_user_profiles_updated_at ON user_profiles IS 'Trigger that automatically updates updated_at column before any update operation';

-- ============================================================================
-- Migration Complete
-- ============================================================================
-- The user_profiles table is now ready with:
-- ✓ All required columns and constraints
-- ✓ Index for fast lookups
-- ✓ Row Level Security enabled with appropriate policies
-- ✓ Automatic timestamp updates via trigger
-- ============================================================================
