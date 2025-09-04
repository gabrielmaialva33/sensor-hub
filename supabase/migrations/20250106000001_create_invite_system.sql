-- Migration: Create invite system for SensorHub authentication
-- This creates invite codes table, functions, and policies for secure invite-based registration

-- Enable RLS (Row Level Security) if not already enabled
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-super-secret-jwt-token-with-at-least-32-characters-long';

-- Create invite_codes table
CREATE TABLE IF NOT EXISTS public.invite_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT UNIQUE NOT NULL,
    email TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW() + INTERVAL '7 days'),
    used_at TIMESTAMP WITH TIME ZONE,
    used_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    max_uses INTEGER DEFAULT 1,
    current_uses INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    
    -- Constraints
    CHECK (current_uses <= max_uses),
    CHECK (expires_at > created_at)
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_invite_codes_code ON public.invite_codes(code);
CREATE INDEX IF NOT EXISTS idx_invite_codes_email ON public.invite_codes(email);
CREATE INDEX IF NOT EXISTS idx_invite_codes_expires_at ON public.invite_codes(expires_at);
CREATE INDEX IF NOT EXISTS idx_invite_codes_created_by ON public.invite_codes(created_by);

-- Enable Row Level Security
ALTER TABLE public.invite_codes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for invite_codes
-- Admin users can see all invites they created
CREATE POLICY "Users can view their own invite codes" ON public.invite_codes
    FOR SELECT USING (created_by = auth.uid());

-- Admin users can create invite codes
CREATE POLICY "Authenticated users can create invite codes" ON public.invite_codes
    FOR INSERT WITH CHECK (created_by = auth.uid());

-- Admin users can update their own invite codes
CREATE POLICY "Users can update their own invite codes" ON public.invite_codes
    FOR UPDATE USING (created_by = auth.uid());

-- Function to generate a random invite code
CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS TEXT AS $$
DECLARE
    code TEXT;
    exists_check BOOLEAN;
BEGIN
    LOOP
        -- Generate 8-character alphanumeric code
        code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));
        
        -- Check if code already exists
        SELECT EXISTS(SELECT 1 FROM public.invite_codes WHERE invite_codes.code = code) INTO exists_check;
        
        -- Exit loop if code is unique
        EXIT WHEN NOT exists_check;
    END LOOP;
    
    RETURN code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate invite code
CREATE OR REPLACE FUNCTION public.validate_invite_code(invite_code TEXT)
RETURNS TABLE (
    is_valid BOOLEAN,
    invite_id UUID,
    error_message TEXT
) AS $$
DECLARE
    invite_record public.invite_codes%ROWTYPE;
BEGIN
    -- Get invite code record
    SELECT * INTO invite_record 
    FROM public.invite_codes 
    WHERE code = invite_code;
    
    -- Check if invite exists
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, NULL::UUID, 'Invalid invite code'::TEXT;
        RETURN;
    END IF;
    
    -- Check if invite has expired
    IF invite_record.expires_at < NOW() THEN
        RETURN QUERY SELECT FALSE, invite_record.id, 'Invite code has expired'::TEXT;
        RETURN;
    END IF;
    
    -- Check if invite has been used up
    IF invite_record.current_uses >= invite_record.max_uses THEN
        RETURN QUERY SELECT FALSE, invite_record.id, 'Invite code has been fully used'::TEXT;
        RETURN;
    END IF;
    
    -- Invite is valid
    RETURN QUERY SELECT TRUE, invite_record.id, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to use invite code (increment usage)
CREATE OR REPLACE FUNCTION public.use_invite_code(invite_code TEXT, user_id UUID DEFAULT auth.uid())
RETURNS TABLE (
    success BOOLEAN,
    error_message TEXT
) AS $$
DECLARE
    validation_result RECORD;
    invite_record public.invite_codes%ROWTYPE;
BEGIN
    -- Validate the invite code first
    SELECT * INTO validation_result FROM public.validate_invite_code(invite_code);
    
    IF NOT validation_result.is_valid THEN
        RETURN QUERY SELECT FALSE, validation_result.error_message;
        RETURN;
    END IF;
    
    -- Get the invite record
    SELECT * INTO invite_record 
    FROM public.invite_codes 
    WHERE id = validation_result.invite_id;
    
    -- Update the invite code usage
    UPDATE public.invite_codes 
    SET 
        current_uses = current_uses + 1,
        used_at = CASE 
            WHEN current_uses = 0 THEN NOW() 
            ELSE used_at 
        END,
        used_by = CASE 
            WHEN current_uses = 0 THEN user_id 
            ELSE used_by 
        END
    WHERE id = invite_record.id;
    
    RETURN QUERY SELECT TRUE, NULL::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create invite code (for admin use)
CREATE OR REPLACE FUNCTION public.create_invite_code(
    p_email TEXT DEFAULT NULL,
    p_expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    p_max_uses INTEGER DEFAULT 1,
    p_metadata JSONB DEFAULT '{}'
)
RETURNS TABLE (
    invite_id UUID,
    invite_code TEXT,
    expires_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    new_code TEXT;
    new_invite_id UUID;
BEGIN
    -- Generate unique code
    new_code := public.generate_invite_code();
    
    -- Insert new invite
    INSERT INTO public.invite_codes (
        code, 
        email, 
        created_by, 
        expires_at, 
        max_uses, 
        metadata
    ) VALUES (
        new_code,
        p_email,
        auth.uid(),
        p_expires_at,
        p_max_uses,
        p_metadata
    ) RETURNING id INTO new_invite_id;
    
    RETURN QUERY SELECT new_invite_id, new_code, p_expires_at;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to cleanup expired invites (run periodically)
CREATE OR REPLACE FUNCTION public.cleanup_expired_invites()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.invite_codes 
    WHERE expires_at < NOW() - INTERVAL '30 days'
    AND used_at IS NULL;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.invite_codes TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_invite_code() TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_invite_code(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.use_invite_code(TEXT, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_invite_code(TEXT, TIMESTAMP WITH TIME ZONE, INTEGER, JSONB) TO authenticated;

-- Create a trigger to auto-cleanup expired invites daily
CREATE OR REPLACE FUNCTION public.trigger_cleanup_expired_invites()
RETURNS TRIGGER AS $$
BEGIN
    -- Run cleanup every 100 new invites created (approximate daily cleanup)
    IF (random() * 100)::int = 1 THEN
        PERFORM public.cleanup_expired_invites();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cleanup_expired_invites_trigger
    AFTER INSERT ON public.invite_codes
    FOR EACH ROW EXECUTE FUNCTION public.trigger_cleanup_expired_invites();

-- Insert some default invite codes for development
-- WARNING: Remove or change these in production!
INSERT INTO public.invite_codes (code, expires_at, max_uses, metadata) VALUES 
    ('DEV12345', NOW() + INTERVAL '30 days', 10, '{"type": "development", "description": "Development invite code"}'),
    ('BETA2025', NOW() + INTERVAL '90 days', 100, '{"type": "beta", "description": "Beta testing invite code"}')
ON CONFLICT (code) DO NOTHING;

-- Comments for documentation
COMMENT ON TABLE public.invite_codes IS 'Stores invite codes for user registration system';
COMMENT ON FUNCTION public.generate_invite_code() IS 'Generates a unique 8-character alphanumeric invite code';
COMMENT ON FUNCTION public.validate_invite_code(TEXT) IS 'Validates an invite code and returns validation status';
COMMENT ON FUNCTION public.use_invite_code(TEXT, UUID) IS 'Marks an invite code as used by incrementing usage count';
COMMENT ON FUNCTION public.create_invite_code(TEXT, TIMESTAMP WITH TIME ZONE, INTEGER, JSONB) IS 'Creates a new invite code with specified parameters';