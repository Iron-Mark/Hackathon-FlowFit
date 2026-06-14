-- Migration: Add Buddy onboarding columns to user_profiles table
-- Description: Adds optional nickname and is_kids_mode columns for Buddy onboarding flow

-- Add nickname column (optional user nickname for kids mode)
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS nickname TEXT CHECK (char_length(nickname) <= 50);

-- Add is_kids_mode column (indicates if user is using kids/Buddy mode)
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS is_kids_mode BOOLEAN NOT NULL DEFAULT FALSE;

-- Add column comments for documentation
COMMENT ON COLUMN user_profiles.nickname IS 'Optional user nickname for kids mode (max 50 characters)';
COMMENT ON COLUMN user_profiles.is_kids_mode IS 'Flag indicating if user is using kids/Buddy mode (default: false)';
