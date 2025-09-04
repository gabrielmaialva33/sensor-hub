-- Create ai_insights table
CREATE TABLE IF NOT EXISTS ai_insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    insight_type TEXT NOT NULL CHECK (insight_type IN (
        'activity_classification',
        'environment_detection', 
        'battery_prediction',
        'movement_analysis',
        'daily_summary',
        'pattern_detection'
    )),
    insight_data JSONB NOT NULL,
    confidence DECIMAL(3,2) CHECK (confidence >= 0.0 AND confidence <= 1.0),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_ai_insights_user_id ON ai_insights(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_insights_type ON ai_insights(insight_type);
CREATE INDEX IF NOT EXISTS idx_ai_insights_timestamp ON ai_insights(timestamp DESC);

-- Enable Row Level Security
ALTER TABLE ai_insights ENABLE ROW LEVEL SECURITY;

-- RLS Policies for ai_insights
CREATE POLICY "Users can view their own AI insights" ON ai_insights
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own AI insights" ON ai_insights
    FOR INSERT WITH CHECK (auth.uid() = user_id);