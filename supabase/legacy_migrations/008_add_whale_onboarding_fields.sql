-- Migration: Add whale-themed onboarding fields
-- Description: Adds wellness_goals and notifications_enabled to user_profiles for the 8-screen whale onboarding flow

-- Add wellness_goals column (multi-select from step 6)
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS wellness_goals TEXT[] DEFAULT '{}';

-- Add notifications_enabled column (from step 7)
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN NOT NULL DEFAULT FALSE;

-- Add column comments for documentation
COMMENT ON COLUMN user_profiles.wellness_goals IS 'Selected wellness goals from onboarding (focus, hygiene, active, stress, social)';
COMMENT ON COLUMN user_profiles.notifications_enabled IS 'Whether user granted notification permissions during onboarding';

-- Create index for wellness_goals array queries
CREATE INDEX IF NOT EXISTS idx_user_profiles_wellness_goals ON user_profiles USING GIN (wellness_goals);
