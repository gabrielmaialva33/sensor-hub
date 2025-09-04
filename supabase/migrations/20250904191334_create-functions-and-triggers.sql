-- Update timestamp function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic updated_at timestamp
CREATE TRIGGER update_sensor_data_updated_at 
    BEFORE UPDATE ON sensor_data 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ai_insights_updated_at 
    BEFORE UPDATE ON ai_insights 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_devices_updated_at 
    BEFORE UPDATE ON devices 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at 
    BEFORE UPDATE ON user_preferences 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Statistics function for user sensor data
CREATE OR REPLACE FUNCTION get_user_sensor_stats(user_id_param UUID)
RETURNS TABLE(
    sensor_type TEXT,
    count BIGINT,
    latest_timestamp TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        sd.sensor_type,
        COUNT(*) as count,
        MAX(sd.timestamp) as latest_timestamp
    FROM sensor_data sd
    WHERE sd.user_id = user_id_param
    GROUP BY sd.sensor_type
    ORDER BY sd.sensor_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Statistics function for user AI insights
CREATE OR REPLACE FUNCTION get_user_insight_stats(user_id_param UUID)
RETURNS TABLE(
    insight_type TEXT,
    count BIGINT,
    avg_confidence NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ai.insight_type,
        COUNT(*) as count,
        AVG(ai.confidence) as avg_confidence
    FROM ai_insights ai
    WHERE ai.user_id = user_id_param
    GROUP BY ai.insight_type
    ORDER BY ai.insight_type;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cleanup function for old data
CREATE OR REPLACE FUNCTION cleanup_old_data(retention_days INTEGER DEFAULT 30)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM sensor_data 
    WHERE timestamp < (NOW() - INTERVAL '1 day' * retention_days);
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;