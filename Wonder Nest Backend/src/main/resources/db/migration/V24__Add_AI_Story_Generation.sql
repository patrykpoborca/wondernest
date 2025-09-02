-- ========================================================================
-- AI Story Generation System - Database Migration V24
-- 
-- This migration implements the core database schema for AI story generation
-- Phase 1: Core AI generation tables and extensions to existing system
-- ========================================================================

-- Set search path to ensure proper table resolution
SET search_path TO public, core, games, content;

-- ========================================================================
-- PHASE 1: AI GENERATION CORE TABLES
-- ========================================================================

-- AI Generation Configuration and Provider Management
CREATE TABLE IF NOT EXISTS ai_generation_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Provider configuration
    provider_name VARCHAR(50) NOT NULL CHECK (provider_name IN ('openai', 'anthropic', 'gemini', 'local_llm')),
    model_name VARCHAR(100) NOT NULL DEFAULT 'gemini-1.5-flash',
    api_endpoint TEXT,
    api_version VARCHAR(20),
    
    -- Generation parameters
    temperature DECIMAL(3,2) DEFAULT 0.7 CHECK (temperature >= 0.0 AND temperature <= 2.0),
    max_tokens INTEGER DEFAULT 4000 CHECK (max_tokens > 0),
    top_p DECIMAL(3,2) DEFAULT 0.9 CHECK (top_p >= 0.0 AND top_p <= 1.0),
    frequency_penalty DECIMAL(3,2) DEFAULT 0.3 CHECK (frequency_penalty >= -2.0 AND frequency_penalty <= 2.0),
    presence_penalty DECIMAL(3,2) DEFAULT 0.3 CHECK (presence_penalty >= -2.0 AND presence_penalty <= 2.0),
    
    -- Safety and content filters
    content_filters JSONB DEFAULT '{"violence": "strict", "scary_content": "moderate", "educational_required": true}',
    age_appropriateness_check BOOLEAN DEFAULT true,
    profanity_filter BOOLEAN DEFAULT true,
    
    -- Rate limiting and cost control
    requests_per_minute INTEGER DEFAULT 60,
    requests_per_day INTEGER DEFAULT 1000,
    tokens_per_minute INTEGER DEFAULT 100000,
    cost_per_1k_prompt_tokens DECIMAL(10,6),
    cost_per_1k_completion_tokens DECIMAL(10,6),
    
    -- Provider status
    is_active BOOLEAN DEFAULT true,
    is_primary BOOLEAN DEFAULT false,
    health_check_url TEXT,
    last_health_check TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- User Generation Quotas and Subscription Tiers
CREATE TABLE IF NOT EXISTS ai_generation_quotas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES core.users(id),
    
    -- Quota limits by subscription tier
    daily_limit INTEGER DEFAULT 5 CHECK (daily_limit >= 0),
    monthly_limit INTEGER DEFAULT 50 CHECK (monthly_limit >= 0),
    total_lifetime_limit INTEGER CHECK (total_lifetime_limit IS NULL OR total_lifetime_limit >= 0),
    
    -- Current usage tracking
    daily_used INTEGER DEFAULT 0 CHECK (daily_used >= 0),
    monthly_used INTEGER DEFAULT 0 CHECK (monthly_used >= 0),
    total_used INTEGER DEFAULT 0 CHECK (total_used >= 0),
    
    -- Reset tracking
    daily_reset_at TIMESTAMP WITH TIME ZONE DEFAULT date_trunc('day', CURRENT_TIMESTAMP + INTERVAL '1 day'),
    monthly_reset_at TIMESTAMP WITH TIME ZONE DEFAULT date_trunc('month', CURRENT_TIMESTAMP + INTERVAL '1 month'),
    
    -- Subscription and bonus credits
    subscription_tier VARCHAR(50) DEFAULT 'free' CHECK (subscription_tier IN ('free', 'family', 'creator', 'educator', 'enterprise')),
    bonus_credits INTEGER DEFAULT 0 CHECK (bonus_credits >= 0),
    credits_expire_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure usage doesn't exceed limits
    CONSTRAINT quota_daily_check CHECK (daily_used <= daily_limit),
    CONSTRAINT quota_monthly_check CHECK (monthly_used <= monthly_limit),
    CONSTRAINT quota_lifetime_check CHECK (total_lifetime_limit IS NULL OR total_used <= total_lifetime_limit)
);

-- AI Story Generation Requests and Tracking
CREATE TABLE IF NOT EXISTS ai_story_generations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Requester information
    parent_id UUID NOT NULL REFERENCES core.users(id),
    child_id UUID REFERENCES core.children(id), -- Target child for story
    family_id UUID NOT NULL REFERENCES core.families(id),
    
    -- Generation input
    user_prompt TEXT NOT NULL,
    selected_images UUID[] DEFAULT '{}', -- References to core.uploaded_files(id)
    target_age_range VARCHAR(20) DEFAULT '3-5' CHECK (target_age_range IN ('3-5', '6-8', '9-12', '13+')),
    story_theme VARCHAR(100),
    educational_goals TEXT[] DEFAULT '{}',
    
    -- Generation parameters used
    provider_id UUID REFERENCES ai_generation_config(id),
    model_parameters JSONB DEFAULT '{}',
    content_safety_level VARCHAR(20) DEFAULT 'strict' CHECK (content_safety_level IN ('strict', 'moderate', 'permissive')),
    
    -- Generation status and timing
    status VARCHAR(30) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'parent_review')),
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    processing_duration_ms INTEGER,
    
    -- Generation output
    generated_story_id UUID REFERENCES story_templates(id), -- Links to actual story
    raw_llm_response JSONB, -- Full LLM response for debugging
    token_usage JSONB DEFAULT '{}', -- prompt_tokens, completion_tokens, total_tokens
    generation_cost DECIMAL(8,4),
    
    -- Safety and quality scores
    safety_score DECIMAL(3,2) CHECK (safety_score >= 0.0 AND safety_score <= 1.0),
    quality_score DECIMAL(3,2) CHECK (quality_score >= 0.0 AND quality_score <= 1.0),
    age_appropriateness_score DECIMAL(3,2) CHECK (age_appropriateness_score >= 0.0 AND age_appropriateness_score <= 1.0),
    
    -- Error handling
    error_message TEXT,
    error_code VARCHAR(50),
    retry_count INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- AI Prompt Templates for Community Sharing
CREATE TABLE IF NOT EXISTS ai_prompt_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Template metadata
    creator_id UUID NOT NULL REFERENCES core.users(id),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50) DEFAULT 'general' CHECK (category IN ('adventure', 'educational', 'bedtime', 'fantasy', 'science', 'history', 'general')),
    
    -- Template content
    base_prompt TEXT NOT NULL,
    placeholder_variables JSONB DEFAULT '{}', -- {character_name, setting, moral_lesson, etc}
    recommended_age_range VARCHAR(20),
    required_images INTEGER DEFAULT 0 CHECK (required_images >= 0),
    
    -- Usage and performance
    usage_count INTEGER DEFAULT 0,
    success_rate DECIMAL(3,2) DEFAULT 0.0 CHECK (success_rate >= 0.0 AND success_rate <= 1.0),
    average_rating DECIMAL(2,1) DEFAULT 0.0 CHECK (average_rating >= 0.0 AND average_rating <= 5.0),
    
    -- Marketplace integration
    is_public BOOLEAN DEFAULT false,
    price_cents INTEGER DEFAULT 0 CHECK (price_cents >= 0),
    revenue_share_percentage INTEGER DEFAULT 70 CHECK (revenue_share_percentage >= 0 AND revenue_share_percentage <= 100),
    
    -- Quality control
    is_verified BOOLEAN DEFAULT false,
    moderation_status VARCHAR(20) DEFAULT 'pending' CHECK (moderation_status IN ('pending', 'approved', 'rejected', 'under_review')),
    moderation_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT unique_creator_template_name UNIQUE(creator_id, name)
);

-- Image Analysis Cache for AI Vision Processing
CREATE TABLE IF NOT EXISTS ai_image_analysis_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Image reference
    file_id UUID NOT NULL UNIQUE REFERENCES core.uploaded_files(id),
    file_hash VARCHAR(64) NOT NULL, -- For cache validation
    
    -- Vision analysis results
    detected_objects JSONB DEFAULT '{}', -- Objects, people, animals detected
    scene_description TEXT,
    character_analysis JSONB DEFAULT '{}', -- Age, gender, emotions, clothing
    setting_analysis JSONB DEFAULT '{}', -- Indoor/outdoor, time of day, location
    visual_style JSONB DEFAULT '{}', -- Art style, colors, mood
    
    -- Safety analysis
    safety_classification JSONB DEFAULT '{}',
    age_appropriate_score DECIMAL(3,2) CHECK (age_appropriate_score >= 0.0 AND age_appropriate_score <= 1.0),
    content_warnings TEXT[],
    
    -- Processing metadata
    analysis_provider VARCHAR(50) DEFAULT 'gemini',
    analysis_model VARCHAR(100),
    processing_time_ms INTEGER,
    analysis_cost DECIMAL(6,4),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP + INTERVAL '30 days'
);

-- ========================================================================
-- EXTEND EXISTING TABLES FOR AI INTEGRATION
-- ========================================================================

-- Extend story_templates to support AI-generated content
ALTER TABLE story_templates 
    ADD COLUMN IF NOT EXISTS creator_type VARCHAR(20) DEFAULT 'human' 
        CHECK (creator_type IN ('human', 'ai_assisted', 'fully_ai')),
    ADD COLUMN IF NOT EXISTS ai_generation_id UUID REFERENCES ai_story_generations(id),
    ADD COLUMN IF NOT EXISTS ai_model_used VARCHAR(100),
    ADD COLUMN IF NOT EXISTS generation_prompt TEXT,
    ADD COLUMN IF NOT EXISTS ai_confidence_score DECIMAL(3,2) CHECK (ai_confidence_score IS NULL OR (ai_confidence_score >= 0.0 AND ai_confidence_score <= 1.0));

-- Extend uploaded_files for AI analysis integration  
ALTER TABLE core.uploaded_files 
    ADD COLUMN IF NOT EXISTS ai_analyzed BOOLEAN DEFAULT false,
    ADD COLUMN IF NOT EXISTS ai_description TEXT,
    ADD COLUMN IF NOT EXISTS detected_content_type VARCHAR(50),
    ADD COLUMN IF NOT EXISTS ai_safety_approved BOOLEAN DEFAULT false;

-- Extend marketplace_listings for AI content source tracking
ALTER TABLE marketplace_listings 
    ADD COLUMN IF NOT EXISTS content_source VARCHAR(20) DEFAULT 'human' 
        CHECK (content_source IN ('human', 'ai_assisted', 'fully_ai')),
    ADD COLUMN IF NOT EXISTS ai_transparency_label TEXT;

-- ========================================================================
-- PERFORMANCE INDEXES
-- ========================================================================

-- AI generation tracking indexes
CREATE INDEX IF NOT EXISTS idx_ai_generations_parent_id ON ai_story_generations(parent_id);
CREATE INDEX IF NOT EXISTS idx_ai_generations_status ON ai_story_generations(status);
CREATE INDEX IF NOT EXISTS idx_ai_generations_created_at ON ai_story_generations(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_generations_provider_id ON ai_story_generations(provider_id);

-- Quota tracking indexes
CREATE INDEX IF NOT EXISTS idx_ai_quotas_user_id ON ai_generation_quotas(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_quotas_daily_reset ON ai_generation_quotas(daily_reset_at);
CREATE INDEX IF NOT EXISTS idx_ai_quotas_monthly_reset ON ai_generation_quotas(monthly_reset_at);

-- Template discovery indexes
CREATE INDEX IF NOT EXISTS idx_ai_templates_creator_id ON ai_prompt_templates(creator_id);
CREATE INDEX IF NOT EXISTS idx_ai_templates_category ON ai_prompt_templates(category);
CREATE INDEX IF NOT EXISTS idx_ai_templates_public ON ai_prompt_templates(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_ai_templates_moderation ON ai_prompt_templates(moderation_status);

-- Image analysis cache indexes
CREATE INDEX IF NOT EXISTS idx_ai_image_cache_file_id ON ai_image_analysis_cache(file_id);
CREATE INDEX IF NOT EXISTS idx_ai_image_cache_expires_at ON ai_image_analysis_cache(expires_at);

-- Extended table indexes
CREATE INDEX IF NOT EXISTS idx_story_templates_creator_type ON story_templates(creator_type);
CREATE INDEX IF NOT EXISTS idx_story_templates_ai_generation_id ON story_templates(ai_generation_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_listings_content_source ON marketplace_listings(content_source);

-- ========================================================================
-- TRIGGERS AND AUTOMATION
-- ========================================================================

-- Update timestamps trigger for ai_generation_config
CREATE OR REPLACE FUNCTION update_ai_generation_config_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ai_generation_config_updated_at
    BEFORE UPDATE ON ai_generation_config
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_generation_config_updated_at();

-- Update timestamps trigger for ai_generation_quotas
CREATE OR REPLACE FUNCTION update_ai_generation_quotas_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ai_generation_quotas_updated_at
    BEFORE UPDATE ON ai_generation_quotas
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_generation_quotas_updated_at();

-- Update timestamps trigger for ai_story_generations
CREATE OR REPLACE FUNCTION update_ai_story_generations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_ai_story_generations_updated_at
    BEFORE UPDATE ON ai_story_generations
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_story_generations_updated_at();

-- Automatic quota initialization for new users
CREATE OR REPLACE FUNCTION create_user_ai_quota()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO ai_generation_quotas (user_id, subscription_tier)
    VALUES (NEW.id, 'free');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_user_ai_quota
    AFTER INSERT ON core.users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_ai_quota();

-- ========================================================================
-- SEED DATA
-- ========================================================================

-- Insert default Gemini configuration
INSERT INTO ai_generation_config (
    provider_name, 
    model_name, 
    api_endpoint,
    is_primary,
    temperature,
    max_tokens,
    cost_per_1k_prompt_tokens,
    cost_per_1k_completion_tokens,
    content_filters
) VALUES (
    'gemini',
    'gemini-1.5-flash',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    true,
    0.7,
    4000,
    0.00015, -- Gemini Flash pricing
    0.0006,
    '{"violence": "strict", "scary_content": "moderate", "educational_required": true, "age_verification": "required"}'
) ON CONFLICT DO NOTHING;

-- Insert sample prompt templates
INSERT INTO ai_prompt_templates (
    creator_id,
    name,
    description,
    category,
    base_prompt,
    placeholder_variables,
    recommended_age_range,
    required_images,
    is_public,
    is_verified
) VALUES (
    (SELECT id FROM core.users LIMIT 1),
    'Adventure Quest Template',
    'Create exciting adventure stories with custom characters',
    'adventure',
    'Create an educational adventure story featuring {character_name} who discovers {magical_item} and must learn about {educational_topic}. The story should be appropriate for ages {age_range} and teach {learning_objective}.',
    '{"character_name": "Main character name", "magical_item": "Special object they find", "educational_topic": "Science or history topic", "age_range": "Target age group", "learning_objective": "What children should learn"}',
    '6-8',
    2,
    true,
    true
) ON CONFLICT (creator_id, name) DO NOTHING;

-- ========================================================================
-- CLEANUP AND MAINTENANCE
-- ========================================================================

-- Create cleanup function for expired image analysis cache
CREATE OR REPLACE FUNCTION cleanup_expired_ai_cache()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM ai_image_analysis_cache 
    WHERE expires_at < CURRENT_TIMESTAMP;
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions for application user
GRANT SELECT, INSERT, UPDATE ON ai_generation_config TO wondernest_app;
GRANT SELECT, INSERT, UPDATE ON ai_generation_quotas TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ai_story_generations TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ai_prompt_templates TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ai_image_analysis_cache TO wondernest_app;

GRANT USAGE ON SEQUENCE ai_generation_config_id_seq TO wondernest_app;
GRANT USAGE ON SEQUENCE ai_generation_quotas_id_seq TO wondernest_app;
GRANT USAGE ON SEQUENCE ai_story_generations_id_seq TO wondernest_app;
GRANT USAGE ON SEQUENCE ai_prompt_templates_id_seq TO wondernest_app;
GRANT USAGE ON SEQUENCE ai_image_analysis_cache_id_seq TO wondernest_app;

-- Migration completed
SELECT 'AI Story Generation System V24 migration completed successfully' AS migration_status;