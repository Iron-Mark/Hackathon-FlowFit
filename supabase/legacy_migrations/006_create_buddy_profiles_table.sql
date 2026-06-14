-- Migration: Create buddy_profiles table for Buddy companion pet system
-- Description: Stores customization and progression data for user's Buddy companion

-- Create buddy_profiles table
CREATE TABLE IF NOT EXISTS buddy_profiles (
  -- Primary identification
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Buddy customization
  name TEXT NOT NULL CHECK (char_length(name) >= 1 AND char_length(name) <= 20),
  color TEXT NOT NULL DEFAULT 'blue',
  
  -- Progression system
  level INTEGER NOT NULL DEFAULT 1 CHECK (level >= 1),
  xp INTEGER NOT NULL DEFAULT 0 CHECK (xp >= 0),
  
  -- Unlocked features
  unlocked_colors TEXT[] NOT NULL DEFAULT ARRAY['blue'],
  accessories JSONB DEFAULT '{}',
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_buddy_profiles_user_id ON buddy_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_buddy_profiles_level ON buddy_profiles(level);

-- Enable Row Level Security
ALTER TABLE buddy_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own buddy profile
CREATE POLICY "Users can view own buddy profile"
  ON buddy_profiles
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own buddy profile
CREATE POLICY "Users can insert own buddy profile"
  ON buddy_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own buddy profile
CREATE POLICY "Users can update own buddy profile"
  ON buddy_profiles
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can delete their own buddy profile
CREATE POLICY "Users can delete own buddy profile"
  ON buddy_profiles
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Apply updated_at trigger
CREATE TRIGGER update_buddy_profiles_updated_at
  BEFORE UPDATE ON buddy_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add table and column comments for documentation
COMMENT ON TABLE buddy_profiles IS 'Stores Buddy companion pet customization and progression data';
COMMENT ON COLUMN buddy_profiles.user_id IS 'Foreign key reference to auth.users table - unique per user';
COMMENT ON COLUMN buddy_profiles.name IS 'Buddy name chosen by user (1-20 characters)';
COMMENT ON COLUMN buddy_profiles.color IS 'Current Buddy color (e.g., blue, green, purple)';
COMMENT ON COLUMN buddy_profiles.level IS 'Buddy level (starts at 1, increases with user activity)';
COMMENT ON COLUMN buddy_profiles.xp IS 'Experience points earned through activities';
COMMENT ON COLUMN buddy_profiles.unlocked_colors IS 'Array of colors unlocked by the user';
COMMENT ON COLUMN buddy_profiles.accessories IS 'JSON object storing unlocked accessories (future expansion)';
COMMENT ON COLUMN buddy_profiles.created_at IS 'Timestamp when buddy profile was created';
COMMENT ON COLUMN buddy_profiles.updated_at IS 'Timestamp when buddy profile was last updated (auto-updated by trigger)';
