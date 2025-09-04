-- Migration: Create health goals and preferences system for SensorHub
-- This creates tables for managing user health goals, achievements, and wellness tracking

-- Create health_goals table
CREATE TABLE IF NOT EXISTS public.health_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Goal Definition
    goal_type TEXT NOT NULL CHECK (goal_type IN (
        'daily_steps', 'weekly_exercise', 'sleep_hours', 'calorie_burn',
        'weight_loss', 'weight_gain', 'hydration', 'meditation',
        'active_minutes', 'distance_walked', 'heart_rate_zone',
        'custom'
    )),
    title TEXT NOT NULL,
    description TEXT,
    
    -- Goal Values
    target_value NUMERIC NOT NULL CHECK (target_value > 0),
    current_value NUMERIC DEFAULT 0,
    unit TEXT NOT NULL, -- steps, minutes, hours, calories, kg, lbs, oz, ml, etc.
    
    -- Time Frame
    frequency TEXT NOT NULL DEFAULT 'daily' CHECK (frequency IN ('daily', 'weekly', 'monthly', 'custom')),
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    
    -- Status and Progress
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed', 'cancelled')),
    progress_percentage NUMERIC DEFAULT 0 CHECK (progress_percentage >= 0 AND progress_percentage <= 100),
    streak_count INTEGER DEFAULT 0,
    best_streak INTEGER DEFAULT 0,
    
    -- Reminder Settings
    reminder_enabled BOOLEAN DEFAULT TRUE,
    reminder_time TIME,
    reminder_days INTEGER[] DEFAULT ARRAY[1,2,3,4,5,6,7], -- 1=Monday, 7=Sunday
    
    -- Visibility and Sharing
    is_public BOOLEAN DEFAULT FALSE,
    allow_friends_view BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    priority_level INTEGER DEFAULT 1 CHECK (priority_level BETWEEN 1 AND 5),
    category TEXT DEFAULT 'fitness',
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CHECK (end_date IS NULL OR end_date >= start_date),
    CHECK (current_value >= 0)
);

-- Create health_goal_history table for tracking progress over time
CREATE TABLE IF NOT EXISTS public.health_goal_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    goal_id UUID REFERENCES public.health_goals(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Progress Data
    recorded_value NUMERIC NOT NULL,
    previous_value NUMERIC DEFAULT 0,
    progress_delta NUMERIC GENERATED ALWAYS AS (recorded_value - previous_value) STORED,
    
    -- Time Information
    recorded_date DATE NOT NULL DEFAULT CURRENT_DATE,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Source of Data
    data_source TEXT DEFAULT 'manual' CHECK (data_source IN ('manual', 'sensor', 'import', 'api')),
    source_details JSONB DEFAULT '{}',
    
    -- Metadata
    notes TEXT,
    metadata JSONB DEFAULT '{}'
);

-- Create wellness_metrics table for comprehensive health tracking
CREATE TABLE IF NOT EXISTS public.wellness_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Metric Information
    metric_type TEXT NOT NULL CHECK (metric_type IN (
        'weight', 'body_fat', 'muscle_mass', 'bone_density',
        'blood_pressure_systolic', 'blood_pressure_diastolic',
        'heart_rate_resting', 'heart_rate_max', 'heart_rate_recovery',
        'sleep_quality', 'stress_level', 'energy_level', 'mood',
        'hydration_level', 'body_temperature',
        'custom'
    )),
    metric_name TEXT NOT NULL,
    value NUMERIC NOT NULL,
    unit TEXT NOT NULL,
    
    -- Quality and Context
    quality_score INTEGER CHECK (quality_score BETWEEN 1 AND 10),
    confidence_level NUMERIC CHECK (confidence_level BETWEEN 0 AND 1),
    measurement_context TEXT, -- e.g., "after exercise", "morning", "evening"
    
    -- Time Information
    measured_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    recorded_date DATE NOT NULL DEFAULT CURRENT_DATE,
    
    -- Source Information
    data_source TEXT DEFAULT 'manual' CHECK (data_source IN ('manual', 'sensor', 'device', 'import')),
    device_name TEXT,
    source_metadata JSONB DEFAULT '{}',
    
    -- User Notes
    notes TEXT,
    tags TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create achievements table for gamification
CREATE TABLE IF NOT EXISTS public.achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Achievement Definition
    achievement_type TEXT NOT NULL CHECK (achievement_type IN (
        'streak', 'milestone', 'consistency', 'improvement', 'challenge', 'social'
    )),
    achievement_id TEXT NOT NULL, -- predefined achievement identifier
    title TEXT NOT NULL,
    description TEXT,
    icon_url TEXT,
    
    -- Achievement Data
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    earned_date DATE NOT NULL DEFAULT CURRENT_DATE,
    earned_value NUMERIC, -- the value that earned this achievement
    
    -- Progress Tracking
    progress_when_earned NUMERIC,
    total_required NUMERIC,
    
    -- Visibility
    is_featured BOOLEAN DEFAULT FALSE,
    is_rare BOOLEAN DEFAULT FALSE,
    rarity_level INTEGER DEFAULT 1 CHECK (rarity_level BETWEEN 1 AND 5),
    
    -- Metadata
    category TEXT,
    points_awarded INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_health_goals_user_id ON public.health_goals(user_id);
CREATE INDEX IF NOT EXISTS idx_health_goals_status ON public.health_goals(status);
CREATE INDEX IF NOT EXISTS idx_health_goals_goal_type ON public.health_goals(goal_type);
CREATE INDEX IF NOT EXISTS idx_health_goals_start_date ON public.health_goals(start_date);
CREATE INDEX IF NOT EXISTS idx_health_goals_end_date ON public.health_goals(end_date);

CREATE INDEX IF NOT EXISTS idx_health_goal_history_goal_id ON public.health_goal_history(goal_id);
CREATE INDEX IF NOT EXISTS idx_health_goal_history_user_id ON public.health_goal_history(user_id);
CREATE INDEX IF NOT EXISTS idx_health_goal_history_recorded_date ON public.health_goal_history(recorded_date);

CREATE INDEX IF NOT EXISTS idx_wellness_metrics_user_id ON public.wellness_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_wellness_metrics_type ON public.wellness_metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_wellness_metrics_recorded_date ON public.wellness_metrics(recorded_date);

CREATE INDEX IF NOT EXISTS idx_achievements_user_id ON public.achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_achievements_type ON public.achievements(achievement_type);
CREATE INDEX IF NOT EXISTS idx_achievements_earned_date ON public.achievements(earned_date);

-- Enable Row Level Security
ALTER TABLE public.health_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_goal_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wellness_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

-- RLS Policies
-- Health Goals
CREATE POLICY "Users can view their own goals" ON public.health_goals
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own goals" ON public.health_goals
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own goals" ON public.health_goals
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own goals" ON public.health_goals
    FOR DELETE USING (user_id = auth.uid());

-- Health Goal History
CREATE POLICY "Users can view their own goal history" ON public.health_goal_history
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own goal history" ON public.health_goal_history
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Wellness Metrics
CREATE POLICY "Users can view their own metrics" ON public.wellness_metrics
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own metrics" ON public.wellness_metrics
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own metrics" ON public.wellness_metrics
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete their own metrics" ON public.wellness_metrics
    FOR DELETE USING (user_id = auth.uid());

-- Achievements
CREATE POLICY "Users can view their own achievements" ON public.achievements
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own achievements" ON public.achievements
    FOR INSERT WITH CHECK (user_id = auth.uid());

-- Functions for goal management

-- Function to update goal progress
CREATE OR REPLACE FUNCTION public.update_goal_progress(
    p_goal_id UUID,
    p_new_value NUMERIC,
    p_data_source TEXT DEFAULT 'manual',
    p_notes TEXT DEFAULT NULL
)
RETURNS TABLE (
    goal_completed BOOLEAN,
    new_progress_percentage NUMERIC,
    achievement_earned TEXT[]
) AS $$
DECLARE
    goal_record public.health_goals%ROWTYPE;
    old_value NUMERIC;
    new_percentage NUMERIC;
    is_completed BOOLEAN := FALSE;
    achievements TEXT[] := ARRAY[]::TEXT[];
BEGIN
    -- Get the current goal
    SELECT * INTO goal_record FROM public.health_goals WHERE id = p_goal_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Goal not found';
    END IF;
    
    IF goal_record.user_id != auth.uid() THEN
        RAISE EXCEPTION 'Unauthorized access to goal';
    END IF;
    
    old_value := goal_record.current_value;
    new_percentage := LEAST(100, (p_new_value / goal_record.target_value) * 100);
    
    -- Update the goal
    UPDATE public.health_goals 
    SET 
        current_value = p_new_value,
        progress_percentage = new_percentage,
        updated_at = NOW(),
        completed_at = CASE 
            WHEN new_percentage >= 100 AND status = 'active' THEN NOW() 
            ELSE completed_at 
        END,
        status = CASE 
            WHEN new_percentage >= 100 AND status = 'active' THEN 'completed' 
            ELSE status 
        END
    WHERE id = p_goal_id;
    
    -- Insert history record
    INSERT INTO public.health_goal_history (
        goal_id,
        user_id,
        recorded_value,
        previous_value,
        data_source,
        notes
    ) VALUES (
        p_goal_id,
        auth.uid(),
        p_new_value,
        old_value,
        p_data_source,
        p_notes
    );
    
    -- Check if goal was completed
    is_completed := new_percentage >= 100 AND goal_record.progress_percentage < 100;
    
    -- Award achievements if goal completed
    IF is_completed THEN
        -- Award completion achievement
        INSERT INTO public.achievements (
            user_id,
            achievement_type,
            achievement_id,
            title,
            description,
            earned_value
        ) VALUES (
            auth.uid(),
            'milestone',
            'goal_completed_' || goal_record.goal_type,
            'Goal Completed!',
            'Completed goal: ' || goal_record.title,
            p_new_value
        ) ON CONFLICT DO NOTHING;
        
        achievements := array_append(achievements, 'Goal Completed!');
    END IF;
    
    RETURN QUERY SELECT is_completed, new_percentage, achievements;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate streak for goals
CREATE OR REPLACE FUNCTION public.calculate_goal_streak(p_goal_id UUID)
RETURNS INTEGER AS $$
DECLARE
    streak_count INTEGER := 0;
    current_date DATE := CURRENT_DATE;
    goal_frequency TEXT;
BEGIN
    SELECT frequency INTO goal_frequency 
    FROM public.health_goals 
    WHERE id = p_goal_id;
    
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    
    -- Calculate streak based on frequency
    -- This is a simplified version - in production you'd want more sophisticated logic
    SELECT COUNT(DISTINCT recorded_date) INTO streak_count
    FROM public.health_goal_history
    WHERE goal_id = p_goal_id
    AND recorded_date >= (CURRENT_DATE - INTERVAL '30 days');
    
    RETURN streak_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's health summary
CREATE OR REPLACE FUNCTION public.get_user_health_dashboard(p_user_id UUID DEFAULT auth.uid())
RETURNS TABLE (
    active_goals INTEGER,
    completed_goals INTEGER,
    total_achievements INTEGER,
    current_streaks JSONB,
    recent_metrics JSONB
) AS $$
DECLARE
    dashboard_data RECORD;
BEGIN
    SELECT 
        (SELECT COUNT(*) FROM public.health_goals WHERE user_id = p_user_id AND status = 'active'),
        (SELECT COUNT(*) FROM public.health_goals WHERE user_id = p_user_id AND status = 'completed'),
        (SELECT COUNT(*) FROM public.achievements WHERE user_id = p_user_id),
        '{}',
        '{}'
    INTO dashboard_data;
    
    RETURN QUERY SELECT 
        dashboard_data.count,
        dashboard_data.count,
        dashboard_data.count,
        dashboard_data.jsonb,
        dashboard_data.jsonb;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create default health goals for new users
CREATE OR REPLACE FUNCTION public.create_default_health_goals(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Insert default goals
    INSERT INTO public.health_goals (
        user_id, goal_type, title, description, target_value, unit, frequency
    ) VALUES 
    (p_user_id, 'daily_steps', 'Daily Steps Goal', 'Walk 8,000 steps every day', 8000, 'steps', 'daily'),
    (p_user_id, 'sleep_hours', 'Sleep Goal', 'Get 8 hours of sleep every night', 8, 'hours', 'daily'),
    (p_user_id, 'weekly_exercise', 'Weekly Exercise', 'Exercise for 150 minutes per week', 150, 'minutes', 'weekly')
    ON CONFLICT DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_health_goals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_health_goals_updated_at
    BEFORE UPDATE ON public.health_goals
    FOR EACH ROW EXECUTE FUNCTION public.handle_health_goals_updated_at();

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.health_goals TO authenticated;
GRANT SELECT, INSERT ON public.health_goal_history TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.wellness_metrics TO authenticated;
GRANT SELECT, INSERT ON public.achievements TO authenticated;

GRANT EXECUTE ON FUNCTION public.update_goal_progress(UUID, NUMERIC, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_goal_streak(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_health_dashboard(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_default_health_goals(UUID) TO authenticated;

-- Comments
COMMENT ON TABLE public.health_goals IS 'User-defined health and fitness goals with progress tracking';
COMMENT ON TABLE public.health_goal_history IS 'Historical progress data for health goals';
COMMENT ON TABLE public.wellness_metrics IS 'Comprehensive wellness and health metrics tracking';
COMMENT ON TABLE public.achievements IS 'Gamification achievements earned by users';
COMMENT ON FUNCTION public.update_goal_progress(UUID, NUMERIC, TEXT, TEXT) IS 'Updates goal progress and awards achievements';
COMMENT ON FUNCTION public.calculate_goal_streak(UUID) IS 'Calculates current streak count for a goal';
COMMENT ON FUNCTION public.get_user_health_dashboard(UUID) IS 'Returns summary data for user health dashboard';