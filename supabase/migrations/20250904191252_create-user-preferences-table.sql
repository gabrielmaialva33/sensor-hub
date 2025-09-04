-- Create user_preferences table
CREATE TABLE IF NOT EXISTS user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    preferences JSONB NOT NULL DEFAULT '{}',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id)
);

-- Enable Row Level Security
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policy for user_preferences
CREATE POLICY "Users can manage their own preferences" ON user_preferences
    FOR ALL USING (auth.uid() = user_id);