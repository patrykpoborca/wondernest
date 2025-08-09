-- WonderNest Stored Functions and Procedures
-- Common operations, business logic, and data processing functions
--
-- Usage:
--   psql -U postgres -d wondernest_prod -f 04_create_functions.sql
--
-- Prerequisites:
--   - Tables and indexes created
--   - Connected to wondernest_prod database

-- =============================================================================
-- CORE SCHEMA FUNCTIONS - User Management & Authentication
-- =============================================================================

-- Function to create a new user with proper validation
CREATE OR REPLACE FUNCTION core.create_user(
    p_email VARCHAR(255),
    p_password_hash VARCHAR(255),
    p_first_name VARCHAR(100) DEFAULT NULL,
    p_last_name VARCHAR(100) DEFAULT NULL,
    p_auth_provider core.auth_provider DEFAULT 'email',
    p_external_id VARCHAR(255) DEFAULT NULL,
    p_timezone VARCHAR(50) DEFAULT 'UTC'
) RETURNS UUID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    -- Validate email format
    IF NOT core.is_valid_email(p_email) THEN
        RAISE EXCEPTION 'Invalid email format: %', p_email;
    END IF;
    
    -- Check for existing email
    IF EXISTS(SELECT 1 FROM core.users WHERE email = p_email AND deleted_at IS NULL) THEN
        RAISE EXCEPTION 'Email already exists: %', p_email;
    END IF;
    
    -- Check for existing external ID
    IF p_external_id IS NOT NULL AND EXISTS(
        SELECT 1 FROM core.users 
        WHERE external_id = p_external_id AND auth_provider = p_auth_provider
    ) THEN
        RAISE EXCEPTION 'External ID already exists for provider: % - %', p_auth_provider, p_external_id;
    END IF;
    
    -- Create the user
    INSERT INTO core.users (
        email, password_hash, first_name, last_name, 
        auth_provider, external_id, timezone, status
    ) VALUES (
        p_email, p_password_hash, p_first_name, p_last_name,
        p_auth_provider, p_external_id, p_timezone, 
        CASE WHEN p_auth_provider = 'email' THEN 'pending_verification' ELSE 'active' END
    ) RETURNING id INTO v_user_id;
    
    -- Log the user creation
    INSERT INTO audit.activity_log (user_id, action, table_name, record_id, new_values)
    VALUES (v_user_id, 'create', 'users', v_user_id, jsonb_build_object(
        'email', p_email,
        'auth_provider', p_auth_provider,
        'created_via', 'core.create_user'
    ));
    
    RETURN v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to validate user login
CREATE OR REPLACE FUNCTION core.validate_user_login(
    p_email VARCHAR(255),
    p_password_hash VARCHAR(255)
) RETURNS TABLE(
    user_id UUID,
    is_valid BOOLEAN,
    user_status core.user_status,
    mfa_required BOOLEAN,
    last_login TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        (u.password_hash = p_password_hash AND u.status = 'active' AND u.deleted_at IS NULL) as is_valid,
        u.status,
        u.mfa_enabled,
        u.last_login_at
    FROM core.users u
    WHERE u.email = p_email AND u.deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update user last login
CREATE OR REPLACE FUNCTION core.update_user_login(
    p_user_id UUID,
    p_ip_address INET DEFAULT NULL,
    p_user_agent TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
    UPDATE core.users 
    SET 
        last_login_at = CURRENT_TIMESTAMP,
        login_count = login_count + 1
    WHERE id = p_user_id;
    
    -- Log the login
    INSERT INTO audit.activity_log (user_id, action, table_name, record_id, ip_address, user_agent)
    VALUES (p_user_id, 'login', 'users', p_user_id, p_ip_address, p_user_agent);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to soft delete user (GDPR right to erasure)
CREATE OR REPLACE FUNCTION core.soft_delete_user(
    p_user_id UUID,
    p_reason TEXT DEFAULT 'user_request'
) RETURNS BOOLEAN AS $$
DECLARE
    v_affected_rows INTEGER;
BEGIN
    -- Soft delete the user
    UPDATE core.users 
    SET 
        deleted_at = CURRENT_TIMESTAMP,
        status = 'deleted',
        -- Anonymize PII
        email = 'deleted_' || p_user_id::text || '@wondernest.internal',
        first_name = NULL,
        last_name = NULL,
        phone = NULL
    WHERE id = p_user_id AND deleted_at IS NULL;
    
    GET DIAGNOSTICS v_affected_rows = ROW_COUNT;
    
    IF v_affected_rows > 0 THEN
        -- Log the deletion
        INSERT INTO audit.activity_log (user_id, action, table_name, record_id, metadata)
        VALUES (p_user_id, 'delete', 'users', p_user_id, jsonb_build_object(
            'deletion_reason', p_reason,
            'deletion_type', 'soft_delete'
        ));
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- FAMILY SCHEMA FUNCTIONS - Family Management & Child Profiles
-- =============================================================================

-- Function to create a family and add the creator as a member
CREATE OR REPLACE FUNCTION family.create_family(
    p_creator_user_id UUID,
    p_family_name VARCHAR(200),
    p_timezone VARCHAR(50) DEFAULT 'UTC'
) RETURNS UUID AS $$
DECLARE
    v_family_id UUID;
BEGIN
    -- Create the family
    INSERT INTO family.families (name, created_by, timezone)
    VALUES (p_family_name, p_creator_user_id, p_timezone)
    RETURNING id INTO v_family_id;
    
    -- Add creator as family member
    INSERT INTO family.family_members (family_id, user_id, role)
    VALUES (v_family_id, p_creator_user_id, 'parent');
    
    -- Log the family creation
    INSERT INTO audit.activity_log (user_id, action, table_name, record_id, new_values)
    VALUES (p_creator_user_id, 'create', 'families', v_family_id, jsonb_build_object(
        'family_name', p_family_name,
        'creator_id', p_creator_user_id
    ));
    
    RETURN v_family_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create a child profile with validation
CREATE OR REPLACE FUNCTION family.create_child_profile(
    p_family_id UUID,
    p_first_name VARCHAR(100),
    p_birth_date DATE,
    p_gender VARCHAR(20) DEFAULT NULL,
    p_primary_language VARCHAR(10) DEFAULT 'en',
    p_interests TEXT[] DEFAULT '{}',
    p_created_by_user_id UUID DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_child_id UUID;
    v_age_months INTEGER;
BEGIN
    -- Validate birth date
    IF p_birth_date > CURRENT_DATE THEN
        RAISE EXCEPTION 'Birth date cannot be in the future';
    END IF;
    
    IF p_birth_date < '1900-01-01' THEN
        RAISE EXCEPTION 'Birth date cannot be before 1900';
    END IF;
    
    -- Calculate age in months
    v_age_months := family.calculate_age_months(p_birth_date);
    
    -- Validate age (0-8 years)
    IF v_age_months > 96 THEN
        RAISE EXCEPTION 'Child is too old for the platform (maximum 8 years)';
    END IF;
    
    -- Create the child profile
    INSERT INTO family.child_profiles (
        family_id, first_name, birth_date, gender, 
        primary_language, interests
    ) VALUES (
        p_family_id, p_first_name, p_birth_date, p_gender,
        p_primary_language, p_interests
    ) RETURNING id INTO v_child_id;
    
    -- Log the child profile creation
    INSERT INTO audit.activity_log (
        user_id, child_id, action, table_name, record_id, new_values
    ) VALUES (
        p_created_by_user_id, v_child_id, 'create', 'child_profiles', v_child_id, 
        jsonb_build_object(
            'family_id', p_family_id,
            'first_name', family.anonymize_child_name(p_first_name),
            'age_months', v_age_months
        )
    );
    
    RETURN v_child_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get child's current age group
CREATE OR REPLACE FUNCTION family.get_child_age_group(p_child_id UUID)
RETURNS content.age_group AS $$
DECLARE
    v_age_months INTEGER;
BEGIN
    SELECT family.calculate_age_months(birth_date) INTO v_age_months
    FROM family.child_profiles
    WHERE id = p_child_id AND archived_at IS NULL;
    
    IF v_age_months IS NULL THEN
        RETURN NULL;
    END IF;
    
    CASE 
        WHEN v_age_months < 12 THEN RETURN '0_12_months'::content.age_group;
        WHEN v_age_months < 24 THEN RETURN '12_24_months'::content.age_group;
        WHEN v_age_months < 36 THEN RETURN '2_3_years'::content.age_group;
        WHEN v_age_months < 48 THEN RETURN '3_4_years'::content.age_group;
        WHEN v_age_months < 60 THEN RETURN '4_5_years'::content.age_group;
        WHEN v_age_months < 72 THEN RETURN '5_6_years'::content.age_group;
        ELSE RETURN '6_8_years'::content.age_group;
    END CASE;
END;
$$ LANGUAGE plpgsql STABLE;

-- =============================================================================
-- CONTENT SCHEMA FUNCTIONS - Content Discovery & Recommendations
-- =============================================================================

-- Function to get age-appropriate content for a child
CREATE OR REPLACE FUNCTION content.get_age_appropriate_content(
    p_child_id UUID,
    p_content_type content.content_type DEFAULT NULL,
    p_category_ids UUID[] DEFAULT NULL,
    p_limit INTEGER DEFAULT 20,
    p_offset INTEGER DEFAULT 0,
    p_min_safety_score DECIMAL DEFAULT 0.8
) RETURNS TABLE(
    content_id UUID,
    title VARCHAR(300),
    description TEXT,
    content_type content.content_type,
    primary_url VARCHAR(1000),
    thumbnail_url VARCHAR(500),
    duration_seconds INTEGER,
    safety_score DECIMAL(3,2),
    engagement_score DECIMAL(3,2),
    is_recommended BOOLEAN
) AS $$
DECLARE
    v_child_age_months INTEGER;
    v_child_interests TEXT[];
BEGIN
    -- Get child's age and interests
    SELECT 
        family.calculate_age_months(birth_date),
        interests
    INTO v_child_age_months, v_child_interests
    FROM family.child_profiles
    WHERE id = p_child_id AND archived_at IS NULL;
    
    IF v_child_age_months IS NULL THEN
        RAISE EXCEPTION 'Child not found or archived';
    END IF;
    
    RETURN QUERY
    SELECT 
        ci.id,
        ci.title,
        ci.description,
        ci.content_type,
        ci.primary_url,
        ci.thumbnail_url,
        ci.duration_seconds,
        ci.safety_score,
        ci.engagement_score,
        EXISTS(
            SELECT 1 FROM ml.content_recommendations cr
            WHERE cr.child_id = p_child_id 
            AND cr.content_id = ci.id
            AND cr.expires_at > CURRENT_TIMESTAMP
        ) as is_recommended
    FROM content.items ci
    WHERE ci.status = 'approved'
    AND ci.archived_at IS NULL
    AND ci.min_age_months <= v_child_age_months
    AND ci.max_age_months >= v_child_age_months
    AND ci.safety_score >= p_min_safety_score
    AND (p_content_type IS NULL OR ci.content_type = p_content_type)
    AND (
        p_category_ids IS NULL OR 
        EXISTS(
            SELECT 1 FROM content.item_categories ic
            WHERE ic.content_id = ci.id AND ic.category_id = ANY(p_category_ids)
        )
    )
    ORDER BY 
        ci.engagement_score DESC,
        ci.safety_score DESC,
        ci.published_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Function to record content engagement
CREATE OR REPLACE FUNCTION content.record_engagement(
    p_child_id UUID,
    p_content_id UUID,
    p_started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    p_ended_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_completion_percentage DECIMAL DEFAULT 0.0,
    p_enjoyed_rating INTEGER DEFAULT NULL,
    p_interaction_events JSONB DEFAULT '[]'
) RETURNS UUID AS $$
DECLARE
    v_engagement_id UUID;
    v_duration_seconds INTEGER;
BEGIN
    -- Calculate duration if ended
    IF p_ended_at IS NOT NULL THEN
        v_duration_seconds := EXTRACT(EPOCH FROM (p_ended_at - p_started_at))::INTEGER;
    END IF;
    
    -- Insert engagement record
    INSERT INTO content.engagement (
        child_id, content_id, started_at, ended_at, duration_seconds,
        completion_percentage, enjoyed_rating, interaction_events
    ) VALUES (
        p_child_id, p_content_id, p_started_at, p_ended_at, v_duration_seconds,
        p_completion_percentage, p_enjoyed_rating, p_interaction_events
    ) RETURNING id INTO v_engagement_id;
    
    -- Update content engagement metrics
    UPDATE content.items
    SET view_count = view_count + 1
    WHERE id = p_content_id;
    
    -- Log the engagement
    INSERT INTO audit.activity_log (child_id, action, table_name, record_id, new_values)
    VALUES (p_child_id, 'create', 'content_engagement', v_engagement_id, jsonb_build_object(
        'content_id', p_content_id,
        'duration_seconds', v_duration_seconds,
        'completion_percentage', p_completion_percentage
    ));
    
    RETURN v_engagement_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- AUDIO SCHEMA FUNCTIONS - Speech Analysis Processing
-- =============================================================================

-- Function to start an audio session
CREATE OR REPLACE FUNCTION audio.start_session(
    p_child_id UUID,
    p_location VARCHAR(100) DEFAULT NULL,
    p_device_id VARCHAR(255) DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_session_id UUID;
BEGIN
    INSERT INTO audio.sessions (
        child_id, started_at, status, location, device_id
    ) VALUES (
        p_child_id, CURRENT_TIMESTAMP, 'recording', p_location, p_device_id
    ) RETURNING id INTO v_session_id;
    
    -- Log session start
    INSERT INTO audit.activity_log (child_id, action, table_name, record_id, new_values)
    VALUES (p_child_id, 'create', 'audio_sessions', v_session_id, jsonb_build_object(
        'action', 'session_started',
        'location', p_location
    ));
    
    RETURN v_session_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to end an audio session
CREATE OR REPLACE FUNCTION audio.end_session(
    p_session_id UUID,
    p_audio_quality_score DECIMAL DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    v_duration_seconds INTEGER;
    v_child_id UUID;
BEGIN
    -- Update session end time and calculate duration
    UPDATE audio.sessions
    SET 
        ended_at = CURRENT_TIMESTAMP,
        duration_seconds = EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - started_at))::INTEGER,
        status = 'processing',
        processing_started_at = CURRENT_TIMESTAMP,
        audio_quality_score = p_audio_quality_score
    WHERE id = p_session_id AND ended_at IS NULL
    RETURNING duration_seconds, child_id INTO v_duration_seconds, v_child_id;
    
    IF v_duration_seconds IS NULL THEN
        RETURN FALSE; -- Session not found or already ended
    END IF;
    
    -- Log session end
    INSERT INTO audit.activity_log (child_id, action, table_name, record_id, new_values)
    VALUES (v_child_id, 'update', 'audio_sessions', p_session_id, jsonb_build_object(
        'action', 'session_ended',
        'duration_seconds', v_duration_seconds
    ));
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to record speech metrics
CREATE OR REPLACE FUNCTION audio.record_speech_metrics(
    p_session_id UUID,
    p_child_id UUID,
    p_start_time TIMESTAMP WITH TIME ZONE,
    p_end_time TIMESTAMP WITH TIME ZONE,
    p_word_count INTEGER DEFAULT 0,
    p_unique_word_count INTEGER DEFAULT 0,
    p_conversation_turns INTEGER DEFAULT 0,
    p_clarity_score DECIMAL DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
    v_metrics_id UUID;
BEGIN
    -- Validate the session exists and belongs to child
    IF NOT EXISTS(
        SELECT 1 FROM audio.sessions 
        WHERE id = p_session_id AND child_id = p_child_id
    ) THEN
        RAISE EXCEPTION 'Session not found or does not belong to child';
    END IF;
    
    -- Insert speech metrics
    INSERT INTO audio.speech_metrics (
        session_id, child_id, start_time, end_time,
        word_count, unique_word_count, conversation_turns,
        clarity_score, created_at
    ) VALUES (
        p_session_id, p_child_id, p_start_time, p_end_time,
        p_word_count, p_unique_word_count, p_conversation_turns,
        p_clarity_score, CURRENT_TIMESTAMP
    ) RETURNING id INTO v_metrics_id;
    
    RETURN v_metrics_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- ANALYTICS SCHEMA FUNCTIONS - Daily Metrics & Insights
-- =============================================================================

-- Function to calculate daily metrics for a child
CREATE OR REPLACE FUNCTION analytics.calculate_daily_metrics(
    p_child_id UUID,
    p_date DATE DEFAULT CURRENT_DATE
) RETURNS BOOLEAN AS $$
DECLARE
    v_existing_record UUID;
    v_total_words INTEGER := 0;
    v_unique_words INTEGER := 0;
    v_conversation_turns INTEGER := 0;
    v_audio_sessions INTEGER := 0;
    v_audio_duration INTEGER := 0;
    v_content_sessions INTEGER := 0;
    v_screen_time INTEGER := 0;
    v_educational_time INTEGER := 0;
    v_completed_content INTEGER := 0;
BEGIN
    -- Check if metrics already exist for this date
    SELECT id INTO v_existing_record
    FROM analytics.daily_child_metrics
    WHERE child_id = p_child_id AND date = p_date;
    
    -- Calculate audio metrics
    SELECT 
        COALESCE(SUM(sm.word_count), 0),
        COALESCE(SUM(sm.unique_word_count), 0),
        COALESCE(SUM(sm.conversation_turns), 0),
        COUNT(DISTINCT sm.session_id),
        COALESCE(SUM(EXTRACT(EPOCH FROM (sm.end_time - sm.start_time))/60), 0)
    INTO v_total_words, v_unique_words, v_conversation_turns, v_audio_sessions, v_audio_duration
    FROM audio.speech_metrics sm
    WHERE sm.child_id = p_child_id
    AND DATE(sm.start_time) = p_date;
    
    -- Calculate content engagement metrics
    SELECT 
        COUNT(*),
        COALESCE(SUM(ce.duration_seconds)/60, 0),
        COALESCE(SUM(
            CASE WHEN ci.educational_value_score >= 0.7 
            THEN ce.duration_seconds/60 ELSE 0 END
        ), 0),
        COUNT(CASE WHEN ce.completion_percentage >= 90 THEN 1 END)
    INTO v_content_sessions, v_screen_time, v_educational_time, v_completed_content
    FROM content.engagement ce
    JOIN content.items ci ON ce.content_id = ci.id
    WHERE ce.child_id = p_child_id
    AND DATE(ce.started_at) = p_date;
    
    -- Insert or update daily metrics
    INSERT INTO analytics.daily_child_metrics (
        child_id, date, total_words, unique_words, conversation_turns,
        audio_session_count, total_audio_duration_minutes,
        content_sessions, total_screen_time_minutes, 
        educational_content_minutes, completed_content_count
    ) VALUES (
        p_child_id, p_date, v_total_words, v_unique_words, v_conversation_turns,
        v_audio_sessions, v_audio_duration,
        v_content_sessions, v_screen_time, v_educational_time, v_completed_content
    ) ON CONFLICT (child_id, date) 
    DO UPDATE SET
        total_words = EXCLUDED.total_words,
        unique_words = EXCLUDED.unique_words,
        conversation_turns = EXCLUDED.conversation_turns,
        audio_session_count = EXCLUDED.audio_session_count,
        total_audio_duration_minutes = EXCLUDED.total_audio_duration_minutes,
        content_sessions = EXCLUDED.content_sessions,
        total_screen_time_minutes = EXCLUDED.total_screen_time_minutes,
        educational_content_minutes = EXCLUDED.educational_content_minutes,
        completed_content_count = EXCLUDED.completed_content_count,
        created_at = CURRENT_TIMESTAMP;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get child development insights
CREATE OR REPLACE FUNCTION analytics.get_child_insights(
    p_child_id UUID,
    p_days_back INTEGER DEFAULT 30
) RETURNS JSONB AS $$
DECLARE
    v_insights JSONB;
    v_avg_words DECIMAL;
    v_avg_screen_time DECIMAL;
    v_vocabulary_growth DECIMAL;
    v_milestone_count INTEGER;
BEGIN
    -- Calculate averages over the period
    SELECT 
        AVG(total_words),
        AVG(total_screen_time_minutes),
        COUNT(DISTINCT date)
    INTO v_avg_words, v_avg_screen_time, v_milestone_count
    FROM analytics.daily_child_metrics
    WHERE child_id = p_child_id 
    AND date >= CURRENT_DATE - INTERVAL '%d days' USING p_days_back;
    
    -- Calculate vocabulary growth (comparing first and last week)
    WITH first_week AS (
        SELECT AVG(unique_words) as avg_unique
        FROM analytics.daily_child_metrics
        WHERE child_id = p_child_id
        AND date >= CURRENT_DATE - INTERVAL '%d days' USING p_days_back
        AND date < CURRENT_DATE - INTERVAL '%d days' USING (p_days_back - 7)
        LIMIT 7
    ), last_week AS (
        SELECT AVG(unique_words) as avg_unique
        FROM analytics.daily_child_metrics
        WHERE child_id = p_child_id
        AND date >= CURRENT_DATE - INTERVAL '7 days'
        LIMIT 7
    )
    SELECT 
        CASE WHEN fw.avg_unique > 0 
        THEN (lw.avg_unique - fw.avg_unique) / fw.avg_unique * 100
        ELSE 0 END
    INTO v_vocabulary_growth
    FROM first_week fw, last_week lw;
    
    -- Build insights JSON
    v_insights := jsonb_build_object(
        'period_days', p_days_back,
        'average_daily_words', COALESCE(v_avg_words, 0),
        'average_screen_time_minutes', COALESCE(v_avg_screen_time, 0),
        'vocabulary_growth_percentage', COALESCE(v_vocabulary_growth, 0),
        'data_points', v_milestone_count,
        'generated_at', CURRENT_TIMESTAMP
    );
    
    RETURN v_insights;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- =============================================================================
-- UTILITY FUNCTIONS - Data Management & Maintenance
-- =============================================================================

-- Function to cleanup expired sessions
CREATE OR REPLACE FUNCTION core.cleanup_expired_sessions()
RETURNS INTEGER AS $$
DECLARE
    v_deleted_count INTEGER;
BEGIN
    DELETE FROM core.user_sessions
    WHERE expires_at < CURRENT_TIMESTAMP - INTERVAL '30 days';
    
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to archive old audio sessions
CREATE OR REPLACE FUNCTION audio.archive_old_sessions(
    p_days_old INTEGER DEFAULT 90
) RETURNS INTEGER AS $$
DECLARE
    v_archived_count INTEGER;
BEGIN
    UPDATE audio.sessions
    SET status = 'archived'
    WHERE status = 'completed'
    AND ended_at < CURRENT_TIMESTAMP - (p_days_old || ' days')::INTERVAL;
    
    GET DIAGNOSTICS v_archived_count = ROW_COUNT;
    RETURN v_archived_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get database health metrics
CREATE OR REPLACE FUNCTION admin.get_db_health_metrics()
RETURNS JSONB AS $$
DECLARE
    v_metrics JSONB;
    v_total_users INTEGER;
    v_active_users INTEGER;
    v_total_children INTEGER;
    v_total_content INTEGER;
    v_db_size TEXT;
BEGIN
    -- Get basic counts
    SELECT COUNT(*) INTO v_total_users FROM core.users WHERE deleted_at IS NULL;
    SELECT COUNT(*) INTO v_active_users FROM core.users WHERE status = 'active' AND deleted_at IS NULL;
    SELECT COUNT(*) INTO v_total_children FROM family.child_profiles WHERE archived_at IS NULL;
    SELECT COUNT(*) INTO v_total_content FROM content.items WHERE status = 'approved';
    
    -- Get database size
    SELECT pg_size_pretty(pg_database_size(current_database())) INTO v_db_size;
    
    v_metrics := jsonb_build_object(
        'total_users', v_total_users,
        'active_users', v_active_users,
        'total_children', v_total_children,
        'total_content', v_total_content,
        'database_size', v_db_size,
        'check_time', CURRENT_TIMESTAMP
    );
    
    RETURN v_metrics;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- =============================================================================
-- GRANT PERMISSIONS
-- =============================================================================

-- Grant execute permissions to application role (will be created in security setup)
-- These will be enabled after running 07_security_setup.sql

SELECT 'All functions and procedures created successfully.' AS result;