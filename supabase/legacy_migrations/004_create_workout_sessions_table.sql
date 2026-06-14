-- Migration: Create workout_sessions table for unified workout flow
-- Description: Stores all workout session data including running, walking, and resistance training
-- with mood tracking, GPS routes, and exercise progress

-- Create workout_sessions table
CREATE TABLE IF NOT EXISTS workout_sessions (
  -- Primary identification
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  
  -- Session metadata
  workout_type TEXT NOT NULL CHECK (workout_type IN ('running', 'walking', 'resistance', 'cycling', 'yoga')),
  workout_subtype TEXT, -- 'upper', 'lower', 'free_walk', 'map_mission'
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  duration_seconds INTEGER CHECK (duration_seconds >= 0),
  
  -- Mood tracking fields
  pre_workout_mood INTEGER CHECK (pre_workout_mood BETWEEN 1 AND 5),
  pre_workout_mood_emoji TEXT,
  pre_workout_notes TEXT,
  post_workout_mood INTEGER CHECK (post_workout_mood BETWEEN 1 AND 5),
  post_workout_mood_emoji TEXT,
  post_workout_notes TEXT,
  mood_change INTEGER, -- post - pre
  
  -- Running/Walking specific fields
  distance_km DECIMAL(10,2) CHECK (distance_km >= 0),
  avg_pace DECIMAL(5,2) CHECK (avg_pace >= 0), -- min/km
  route_polyline TEXT, -- encoded GPS route
  steps INTEGER CHECK (steps >= 0),
  elevation_gain_m INTEGER CHECK (elevation_gain_m >= 0),
  
  -- Walking mission specific
  mission_id UUID,
  mission_completed BOOLEAN DEFAULT false,
  
  -- Resistance training specific fields
  exercises_completed JSONB, -- [{name, emoji, sets: [{reps, weight, completed_at}]}]
  total_volume_kg DECIMAL(10,2) CHECK (total_volume_kg >= 0),
  rest_timer_seconds INTEGER CHECK (rest_timer_seconds IN (60, 90, 120)),
  audio_cues_enabled BOOLEAN DEFAULT true,
  hr_monitor_enabled BOOLEAN DEFAULT false,
  time_under_tension INTEGER CHECK (time_under_tension >= 0),
  
  -- General metrics (all workout types)
  avg_heart_rate INTEGER CHECK (avg_heart_rate >= 0 AND avg_heart_rate <= 250),
  max_heart_rate INTEGER CHECK (max_heart_rate >= 0 AND max_heart_rate <= 250),
  heart_rate_zones JSONB, -- {zone1: 300, zone2: 600, ...} seconds in each zone
  calories_burned INTEGER CHECK (calories_burned >= 0),
  
  -- Status tracking
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_workout_sessions_user_id ON workout_sessions(user_id);
CREATE INDEX idx_workout_sessions_start_time ON workout_sessions(start_time DESC);
CREATE INDEX idx_workout_sessions_workout_type ON workout_sessions(workout_type);
CREATE INDEX idx_workout_sessions_status ON workout_sessions(status);
CREATE INDEX idx_workout_sessions_user_type ON workout_sessions(user_id, workout_type);

-- Enable Row Level Security
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can view their own workout sessions
CREATE POLICY "Users can view their own workout sessions"
  ON workout_sessions FOR SELECT
  USING (auth.uid() = user_id);

-- RLS Policy: Users can insert their own workout sessions
CREATE POLICY "Users can insert their own workout sessions"
  ON workout_sessions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RLS Policy: Users can update their own workout sessions
CREATE POLICY "Users can update their own workout sessions"
  ON workout_sessions FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policy: Users can delete their own workout sessions
CREATE POLICY "Users can delete their own workout sessions"
  ON workout_sessions FOR DELETE
  USING (auth.uid() = user_id);

-- Apply updated_at trigger (assumes trigger function exists from migration 003)
CREATE TRIGGER update_workout_sessions_updated_at
  BEFORE UPDATE ON workout_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Add comment to table
COMMENT ON TABLE workout_sessions IS 'Stores all workout session data including running, walking, and resistance training with mood tracking';

-- Add comments to key columns
COMMENT ON COLUMN workout_sessions.mood_change IS 'Calculated as post_workout_mood - pre_workout_mood';
COMMENT ON COLUMN workout_sessions.route_polyline IS 'Encoded GPS route polyline for efficient storage';
COMMENT ON COLUMN workout_sessions.exercises_completed IS 'JSONB array of exercise progress with sets and reps';
COMMENT ON COLUMN workout_sessions.heart_rate_zones IS 'JSONB object mapping zone names to seconds spent in each zone';
