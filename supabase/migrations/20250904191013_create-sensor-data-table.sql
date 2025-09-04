-- Create sensor_data table
CREATE TABLE IF NOT EXISTS sensor_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    sensor_type TEXT NOT NULL CHECK (sensor_type IN (
        'accelerometer', 
        'gyroscope', 
        'magnetometer', 
        'location', 
        'battery', 
        'light', 
        'proximity'
    )),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    data JSONB NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_sensor_data_user_id ON sensor_data(user_id);
CREATE INDEX IF NOT EXISTS idx_sensor_data_sensor_type ON sensor_data(sensor_type);
CREATE INDEX IF NOT EXISTS idx_sensor_data_timestamp ON sensor_data(timestamp);
CREATE INDEX IF NOT EXISTS idx_sensor_data_user_sensor_time ON sensor_data(user_id, sensor_type, timestamp DESC);

-- Enable Row Level Security
ALTER TABLE sensor_data ENABLE ROW LEVEL SECURITY;

-- RLS Policies for sensor_data
CREATE POLICY "Users can view their own sensor data" ON sensor_data
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own sensor data" ON sensor_data
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own sensor data" ON sensor_data
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own sensor data" ON sensor_data
    FOR DELETE USING (auth.uid() = user_id);