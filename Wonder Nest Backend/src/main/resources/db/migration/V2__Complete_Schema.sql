-- V2.0__Complete_Schema.sql
-- Complete WonderNest database schema with all required tables
-- This migration creates all the tables needed for the backend application

-- =============================================================================
-- CORE SCHEMA - User Management and Authentication
-- =============================================================================
SET search_path TO core, public;

-- Add missing columns to users table if they don't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'core' AND table_name = 'users' AND column_name = 'role') THEN
        ALTER TABLE users ADD COLUMN role VARCHAR(50) DEFAULT 'parent';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'core' AND table_name = 'users' AND column_name = 'pin_hash') THEN
        ALTER TABLE users ADD COLUMN pin_hash VARCHAR(255);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'core' AND table_name = 'users' AND column_name = 'family_id') THEN
        ALTER TABLE users ADD COLUMN family_id UUID;
    END IF;
END $$;

-- Refresh tokens table
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE,
    device_id VARCHAR(255),
    ip_address INET
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash ON refresh_tokens(token_hash);

-- =============================================================================
-- FAMILY SCHEMA - Family and Child Management
-- =============================================================================
SET search_path TO family, public;

-- Child profiles table
CREATE TABLE IF NOT EXISTS child_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    nickname VARCHAR(50),
    birth_date DATE NOT NULL,
    gender VARCHAR(20),
    avatar_url TEXT,
    interests TEXT[],
    favorite_colors TEXT[],
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    archived_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_child_profiles_family ON child_profiles(family_id);
CREATE INDEX IF NOT EXISTS idx_child_profiles_active ON child_profiles(is_active);

-- Child settings table
CREATE TABLE IF NOT EXISTS child_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES child_profiles(id) ON DELETE CASCADE,
    content_preferences JSONB DEFAULT '{}',
    time_restrictions JSONB DEFAULT '{}',
    blocked_categories TEXT[],
    allowed_content_types TEXT[],
    max_session_minutes INTEGER DEFAULT 60,
    require_parent_approval BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_child_settings_child ON child_settings(child_id);

-- Family settings table
CREATE TABLE IF NOT EXISTS family_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    content_filter_level VARCHAR(20) DEFAULT 'moderate',
    enable_audio_monitoring BOOLEAN DEFAULT TRUE,
    enable_screen_time_limits BOOLEAN DEFAULT TRUE,
    enable_content_recommendations BOOLEAN DEFAULT TRUE,
    notification_preferences JSONB DEFAULT '{}',
    privacy_settings JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_family_settings_family ON family_settings(family_id);

-- =============================================================================
-- CONTENT SCHEMA - Content Management
-- =============================================================================
SET search_path TO content, public;

-- Content items table
CREATE TABLE IF NOT EXISTS content_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    content_type VARCHAR(50) NOT NULL, -- video, game, story, audio
    category VARCHAR(50),
    url TEXT,
    thumbnail_url TEXT,
    duration_seconds INTEGER,
    age_min INTEGER DEFAULT 2,
    age_max INTEGER DEFAULT 18,
    language VARCHAR(10) DEFAULT 'en',
    tags TEXT[],
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    provider VARCHAR(50), -- youtube, custom, etc
    provider_id VARCHAR(255),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_content_items_type ON content_items(content_type);
CREATE INDEX IF NOT EXISTS idx_content_items_category ON content_items(category);
CREATE INDEX IF NOT EXISTS idx_content_items_age ON content_items(age_min, age_max);
CREATE INDEX IF NOT EXISTS idx_content_items_active ON content_items(is_active);

-- Content filters table
CREATE TABLE IF NOT EXISTS content_filters (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES family.families(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    min_age INTEGER DEFAULT 2,
    max_age INTEGER DEFAULT 18,
    allowed_categories TEXT[],
    blocked_categories TEXT[],
    allowed_providers TEXT[],
    blocked_keywords TEXT[],
    max_duration_minutes INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_content_filters_family ON content_filters(family_id);

-- Content engagement tracking
CREATE TABLE IF NOT EXISTS content_engagement (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES family.child_profiles(id) ON DELETE CASCADE,
    content_id UUID NOT NULL REFERENCES content_items(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    completion_percentage DECIMAL(5,2),
    engagement_score DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_content_engagement_child ON content_engagement(child_id);
CREATE INDEX IF NOT EXISTS idx_content_engagement_content ON content_engagement(content_id);
CREATE INDEX IF NOT EXISTS idx_content_engagement_date ON content_engagement(started_at);

-- =============================================================================
-- ANALYTICS SCHEMA - Analytics and Insights
-- =============================================================================
SET search_path TO analytics, public;

-- Daily child metrics
CREATE TABLE IF NOT EXISTS daily_child_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES family.child_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    screen_time_minutes INTEGER DEFAULT 0,
    content_items_viewed INTEGER DEFAULT 0,
    learning_time_minutes INTEGER DEFAULT 0,
    creative_time_minutes INTEGER DEFAULT 0,
    physical_activity_minutes INTEGER DEFAULT 0,
    social_interaction_minutes INTEGER DEFAULT 0,
    vocabulary_words_learned INTEGER DEFAULT 0,
    stories_completed INTEGER DEFAULT 0,
    games_played INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(child_id, date)
);

CREATE INDEX IF NOT EXISTS idx_daily_metrics_child ON daily_child_metrics(child_id);
CREATE INDEX IF NOT EXISTS idx_daily_metrics_date ON daily_child_metrics(date);

-- Learning insights
CREATE TABLE IF NOT EXISTS learning_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES family.child_profiles(id) ON DELETE CASCADE,
    insight_type VARCHAR(50), -- milestone, recommendation, concern
    category VARCHAR(50),
    title VARCHAR(255),
    description TEXT,
    data JSONB DEFAULT '{}',
    confidence_score DECIMAL(3,2),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_learning_insights_child ON learning_insights(child_id);
CREATE INDEX IF NOT EXISTS idx_learning_insights_type ON learning_insights(insight_type);

-- Analytics events
CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES core.users(id),
    child_id UUID REFERENCES family.child_profiles(id),
    event_type VARCHAR(50) NOT NULL,
    event_category VARCHAR(50),
    event_data JSONB DEFAULT '{}',
    session_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_analytics_events_user ON analytics_events(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_child ON analytics_events(child_id);
CREATE INDEX IF NOT EXISTS idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_analytics_events_date ON analytics_events(created_at);

-- =============================================================================
-- COMPLIANCE SCHEMA - COPPA and Legal Compliance
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS compliance;
SET search_path TO compliance, public;

-- COPPA consent records
CREATE TABLE IF NOT EXISTS coppa_consent (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    family_id UUID NOT NULL REFERENCES family.families(id) ON DELETE CASCADE,
    child_id UUID NOT NULL REFERENCES family.child_profiles(id) ON DELETE CASCADE,
    parent_id UUID NOT NULL REFERENCES core.users(id),
    consent_type VARCHAR(50) NOT NULL, -- data_collection, audio_monitoring, etc
    granted BOOLEAN NOT NULL,
    ip_address INET,
    user_agent TEXT,
    consent_text TEXT,
    version VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS idx_coppa_consent_family ON coppa_consent(family_id);
CREATE INDEX IF NOT EXISTS idx_coppa_consent_child ON coppa_consent(child_id);
CREATE INDEX IF NOT EXISTS idx_coppa_consent_parent ON coppa_consent(parent_id);

-- Data retention policies
CREATE TABLE IF NOT EXISTS data_retention_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    data_type VARCHAR(50) NOT NULL,
    retention_days INTEGER NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- Grant permissions to application users
-- =============================================================================

-- Grant permissions to wondernest_app user
GRANT USAGE ON SCHEMA core, family, content, analytics, compliance, audit TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA family TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA content TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA analytics TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA compliance TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA audit TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA core TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA family TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA content TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA analytics TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA compliance TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA audit TO wondernest_app;

-- Grant read-only permissions to wondernest_analytics user  
GRANT USAGE ON SCHEMA core, family, content, analytics, compliance, audit TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA core TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA family TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA content TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA compliance TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO wondernest_analytics;

-- Update version info
INSERT INTO core.database_info (key, value) VALUES ('schema_version', '2.0.0')
ON CONFLICT (key) DO UPDATE SET value = '2.0.0';