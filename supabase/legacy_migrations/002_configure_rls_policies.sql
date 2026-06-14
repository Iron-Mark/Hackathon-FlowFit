-- Enable Row Level Security on user_profiles table
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

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

-- Add comments to policies for documentation
COMMENT ON POLICY "Users can view own profile" ON user_profiles IS 'Allows users to read only their own profile data';
COMMENT ON POLICY "Users can insert own profile" ON user_profiles IS 'Allows users to create only their own profile record';
COMMENT ON POLICY "Users can update own profile" ON user_profiles IS 'Allows users to update only their own profile data';
