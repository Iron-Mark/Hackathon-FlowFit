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
