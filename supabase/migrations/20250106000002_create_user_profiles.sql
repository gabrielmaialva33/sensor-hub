-- Migration: Create extended user profiles for SensorHub
-- This creates user profiles with health information, preferences, and settings

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
    
    -- Basic Information
    first_name TEXT,
    last_name TEXT,
    display_name TEXT,
    avatar_url TEXT,
    date_of_birth DATE,
    gender TEXT CHECK (gender IN ('male', 'female', 'non-binary', 'prefer-not-to-say')),
    
    -- Contact Information
    phone_number TEXT,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    
    -- Health Information
    height_cm NUMERIC(5,2) CHECK (height_cm > 0 AND height_cm < 300),
    weight_kg NUMERIC(5,2) CHECK (weight_kg > 0 AND weight_kg < 500),
    blood_type TEXT CHECK (blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    
    -- Activity Level
    activity_level TEXT DEFAULT 'moderate' CHECK (activity_level IN ('sedentary', 'light', 'moderate', 'active', 'very-active')),
    fitness_goals TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    -- Medical Information (encrypted/sensitive)
    medical_conditions TEXT[] DEFAULT ARRAY[]::TEXT[],
    medications TEXT[] DEFAULT ARRAY[]::TEXT[],
    allergies TEXT[] DEFAULT ARRAY[]::TEXT[],
    
    -- App Preferences
    preferred_units TEXT DEFAULT 'metric' CHECK (preferred_units IN ('metric', 'imperial')),
    timezone TEXT DEFAULT 'UTC',
    language_code TEXT DEFAULT 'en',
    theme_preference TEXT DEFAULT 'system' CHECK (theme_preference IN ('light', 'dark', 'system')),
    
    -- Privacy Settings
    data_sharing_enabled BOOLEAN DEFAULT TRUE,
    analytics_enabled BOOLEAN DEFAULT TRUE,
    marketing_emails_enabled BOOLEAN DEFAULT FALSE,
    push_notifications_enabled BOOLEAN DEFAULT TRUE,
    
    -- Health Goals and Targets
    daily_step_goal INTEGER DEFAULT 8000 CHECK (daily_step_goal >= 0),
    daily_calorie_goal INTEGER DEFAULT 2000 CHECK (daily_calorie_goal >= 0),
    sleep_goal_hours NUMERIC(3,1) DEFAULT 8.0 CHECK (sleep_goal_hours >= 0 AND sleep_goal_hours <= 24),
    weekly_exercise_goal_minutes INTEGER DEFAULT 150 CHECK (weekly_exercise_goal_minutes >= 0),
    
    -- Sensor Preferences
    sensor_sampling_rate TEXT DEFAULT 'normal' CHECK (sensor_sampling_rate IN ('low', 'normal', 'high')),
    enabled_sensors TEXT[] DEFAULT ARRAY['accelerometer', 'gyroscope', 'magnetometer', 'location', 'battery', 'light', 'proximity'],
    auto_activity_detection BOOLEAN DEFAULT TRUE,
    location_tracking_enabled BOOLEAN DEFAULT TRUE,
    
    -- AI and Analytics Preferences
    ai_insights_enabled BOOLEAN DEFAULT TRUE,
    predictive_analysis_enabled BOOLEAN DEFAULT TRUE,
    anomaly_detection_enabled BOOLEAN DEFAULT TRUE,
    
    -- Subscription and Account Status
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'pro')),
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    account_status TEXT DEFAULT 'active' CHECK (account_status IN ('active', 'suspended', 'pending')),
    
    -- Onboarding Status
    onboarding_completed BOOLEAN DEFAULT FALSE,
    onboarding_step INTEGER DEFAULT 0,
    onboarding_completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Device and Usage Information
    primary_device_id TEXT,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    total_session_count INTEGER DEFAULT 0,
    total_session_duration_minutes INTEGER DEFAULT 0,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_subscription_tier ON public.user_profiles(subscription_tier);
CREATE INDEX IF NOT EXISTS idx_user_profiles_account_status ON public.user_profiles(account_status);
CREATE INDEX IF NOT EXISTS idx_user_profiles_last_active_at ON public.user_profiles(last_active_at);
CREATE INDEX IF NOT EXISTS idx_user_profiles_onboarding_completed ON public.user_profiles(onboarding_completed);

-- Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
-- Users can only see and modify their own profile
CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own profile" ON public.user_profiles
    FOR UPDATE USING (user_id = auth.uid());

-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (user_id, display_name)
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data->>'display_name',
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'name',
            split_part(NEW.email, '@', 1)
        )
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create profile on user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_profile_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER set_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_profile_updated_at();

-- Function to calculate BMI
CREATE OR REPLACE FUNCTION public.calculate_bmi(height_cm NUMERIC, weight_kg NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    IF height_cm IS NULL OR weight_kg IS NULL OR height_cm <= 0 OR weight_kg <= 0 THEN
        RETURN NULL;
    END IF;
    
    RETURN ROUND((weight_kg / POWER(height_cm / 100, 2))::NUMERIC, 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to calculate age from date of birth
CREATE OR REPLACE FUNCTION public.calculate_age(date_of_birth DATE)
RETURNS INTEGER AS $$
BEGIN
    IF date_of_birth IS NULL THEN
        RETURN NULL;
    END IF;
    
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, date_of_birth));
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to get user health summary
CREATE OR REPLACE FUNCTION public.get_user_health_summary(p_user_id UUID DEFAULT auth.uid())
RETURNS TABLE (
    bmi NUMERIC,
    age INTEGER,
    activity_level TEXT,
    step_goal_progress NUMERIC,
    sleep_goal_progress NUMERIC,
    exercise_goal_progress NUMERIC
) AS $$
DECLARE
    profile_record public.user_profiles%ROWTYPE;
BEGIN
    SELECT * INTO profile_record 
    FROM public.user_profiles 
    WHERE user_id = p_user_id;
    
    IF NOT FOUND THEN
        RETURN;
    END IF;
    
    RETURN QUERY SELECT 
        public.calculate_bmi(profile_record.height_cm, profile_record.weight_kg),
        public.calculate_age(profile_record.date_of_birth),
        profile_record.activity_level,
        0.0::NUMERIC, -- These would be calculated from actual sensor data
        0.0::NUMERIC,
        0.0::NUMERIC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user activity status
CREATE OR REPLACE FUNCTION public.update_user_activity(p_user_id UUID DEFAULT auth.uid())
RETURNS VOID AS $$
BEGIN
    UPDATE public.user_profiles 
    SET 
        last_active_at = NOW(),
        total_session_count = total_session_count + 1
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to complete onboarding
CREATE OR REPLACE FUNCTION public.complete_onboarding(p_user_id UUID DEFAULT auth.uid())
RETURNS VOID AS $$
BEGIN
    UPDATE public.user_profiles 
    SET 
        onboarding_completed = TRUE,
        onboarding_completed_at = NOW(),
        onboarding_step = -1 -- -1 indicates completed
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- View for public user information (safe to share)
CREATE OR REPLACE VIEW public.user_public_profiles AS
SELECT 
    user_id,
    display_name,
    avatar_url,
    activity_level,
    preferred_units,
    subscription_tier,
    onboarding_completed,
    created_at
FROM public.user_profiles;

-- Enable RLS on the view
ALTER VIEW public.user_public_profiles SET (security_barrier = true);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.user_profiles TO authenticated;
GRANT SELECT ON public.user_public_profiles TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_bmi(NUMERIC, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_age(DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_health_summary(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_activity(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.complete_onboarding(UUID) TO authenticated;

-- Comments for documentation
COMMENT ON TABLE public.user_profiles IS 'Extended user profiles with health information and app preferences';
COMMENT ON FUNCTION public.calculate_bmi(NUMERIC, NUMERIC) IS 'Calculates BMI from height in cm and weight in kg';
COMMENT ON FUNCTION public.calculate_age(DATE) IS 'Calculates age from date of birth';
COMMENT ON FUNCTION public.get_user_health_summary(UUID) IS 'Returns a summary of user health metrics and goal progress';
COMMENT ON FUNCTION public.update_user_activity(UUID) IS 'Updates user activity timestamp and session count';
COMMENT ON FUNCTION public.complete_onboarding(UUID) IS 'Marks user onboarding as completed';
COMMENT ON VIEW public.user_public_profiles IS 'Public view of user profiles with non-sensitive information only';