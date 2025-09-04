-- Create devices table
CREATE TABLE IF NOT EXISTS devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    device_info JSONB NOT NULL,
    last_seen TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, device_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON devices(user_id);
CREATE INDEX IF NOT EXISTS idx_devices_last_seen ON devices(last_seen DESC);

-- Enable Row Level Security
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

-- RLS Policy for devices
CREATE POLICY "Users can manage their own devices" ON devices
    FOR ALL USING (auth.uid() = user_id);