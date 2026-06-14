-- Migration: Create missions table for walking map missions
-- Description: Stores location-based walking challenges

-- Create missions table
CREATE TABLE IF NOT EXISTS missions (
  -- Primary identification
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  -- Mission details
  mission_type TEXT NOT NULL CHECK (mission_type IN ('target', 'sanctuary', 'safetyNet')),
  name TEXT NOT NULL,
  description TEXT,
  
  -- Location data
  target_latitude DECIMAL(10,8) NOT NULL,
  target_longitude DECIMAL(11,8) NOT NULL,
  target_distance DECIMAL(10,2) CHECK (target_distance >= 0), -- meters (for target missions)
  radius DECIMAL(10,2) CHECK (radius >= 0), -- meters (for safety net missions)
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  completed_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_missions_user_id ON missions(user_id);
CREATE INDEX idx_missions_is_active ON missions(is_active);
CREATE INDEX idx_missions_user_active ON missions(user_id, is_active);

-- Enable Row Level Security
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own missions
CREATE POLICY "Users can view their own missions"
  ON missions FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own missions
CREATE POLICY "Users can insert their own missions"
  ON missions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own missions
CREATE POLICY "Users can update their own missions"
  ON missions FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policy: Users can delete their own missions
CREATE POLICY "Users can delete their own missions"
  ON missions FOR DELETE
  USING (auth.uid() = user_id);

-- Apply updated_at trigger
CREATE TRIGGER update_missions_updated_at
  BEFORE UPDATE ON missions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add comment to table
COMMENT ON TABLE missions IS 'Stores location-based walking missions for map-based workouts';

-- Add comments to key columns
COMMENT ON COLUMN missions.mission_type IS 'Type of mission: target (walk X meters), sanctuary (reach location), safetyNet (stay within radius)';
COMMENT ON COLUMN missions.target_distance IS 'Distance in meters for target missions';
COMMENT ON COLUMN missions.radius IS 'Radius in meters for safety net missions';
