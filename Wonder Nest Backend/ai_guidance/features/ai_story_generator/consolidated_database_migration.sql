-- ========================================================================
-- Integrated AI Story Platform - Comprehensive Database Migration
-- 
-- This migration implements the complete database schema for:
-- 1. AI Story Generation System
-- 2. Community Marketplace Enhancements  
-- 3. Creator Economy Platform
-- 4. Personal Library System
--
-- All changes are additive to preserve existing functionality
-- ========================================================================

SET search_path TO games, public;

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
    user_id UUID NOT NULL REFERENCES core.users(id) UNIQUE,
    
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
    child_id UUID REFERENCES family.child_profiles(id), -- Target child for story
    family_id UUID NOT NULL REFERENCES core.families(id),
    
    -- Generation input
    user_prompt TEXT NOT NULL CHECK (length(user_prompt) >= 10 AND length(user_prompt) <= 2000),
    system_prompt TEXT NOT NULL, -- Constructed system prompt with context
    selected_image_ids UUID[] DEFAULT '{}', -- References core.uploaded_files
    
    -- Story parameters
    age_group VARCHAR(10) NOT NULL CHECK (age_group IN ('3-5', '6-8', '9-12')),
    reading_level VARCHAR(20) NOT NULL CHECK (reading_level IN ('emerging', 'developing', 'fluent', 'advanced')),
    target_pages INTEGER DEFAULT 10 CHECK (target_pages >= 5 AND target_pages <= 20),
    story_theme VARCHAR(100),
    educational_goals TEXT[],
    vocabulary_focus TEXT[],
    tone VARCHAR(50) DEFAULT 'friendly' CHECK (tone IN ('friendly', 'adventurous', 'educational', 'calming', 'exciting')),
    
    -- LLM provider details
    provider_used VARCHAR(50) NOT NULL,
    model_used VARCHAR(100) NOT NULL,
    generation_params JSONB NOT NULL DEFAULT '{}',
    
    -- Generation status and results
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN (
        'pending', 'processing', 'completed', 'failed', 'cancelled', 'moderation_required', 'rejected'
    )),
    
    -- Generated content (stored before creating story_template)
    generated_story_data JSONB, -- Complete story structure
    generated_title VARCHAR(255),
    generated_description TEXT,
    generated_vocabulary JSONB, -- Vocabulary words with definitions
    image_placements JSONB, -- Which images go on which pages
    
    -- LLM API tracking
    llm_request_id VARCHAR(255), -- External API request ID
    llm_request_payload JSONB, -- Full request sent to LLM
    llm_response_payload JSONB, -- Full response from LLM
    prompt_tokens INTEGER CHECK (prompt_tokens >= 0),
    completion_tokens INTEGER CHECK (completion_tokens >= 0),
    total_tokens INTEGER GENERATED ALWAYS AS (COALESCE(prompt_tokens, 0) + COALESCE(completion_tokens, 0)) STORED,
    estimated_cost DECIMAL(10,4) CHECK (estimated_cost >= 0),
    
    -- Safety and content validation
    safety_check_passed BOOLEAN DEFAULT false,
    safety_check_results JSONB,
    content_warnings TEXT[],
    pii_detected BOOLEAN DEFAULT false,
    moderation_notes TEXT,
    
    -- Timing and performance
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    processing_time_ms INTEGER CHECK (processing_time_ms >= 0),
    
    -- Error handling
    error_message TEXT,
    error_code VARCHAR(50),
    retry_count INTEGER DEFAULT 0 CHECK (retry_count <= 3),
    retry_after TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- AI Generated Stories (links to story_templates after approval)
CREATE TABLE IF NOT EXISTS ai_generated_stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    generation_request_id UUID NOT NULL REFERENCES ai_story_generations(id) UNIQUE,
    
    -- Link to created story template (after parent approval)
    story_template_id UUID REFERENCES story_templates(id),
    
    -- Parent approval workflow
    approval_status VARCHAR(50) DEFAULT 'pending_review' CHECK (approval_status IN (
        'pending_review', 'approved', 'rejected', 'edited', 'published_to_marketplace'
    )),
    reviewed_by UUID REFERENCES core.users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    review_notes TEXT,
    
    -- Parent edits (if story was modified before approval)
    has_parent_edits BOOLEAN DEFAULT false,
    original_content JSONB, -- Original AI-generated content
    edited_content JSONB, -- Parent-modified content
    edit_summary TEXT, -- Description of changes made
    edited_at TIMESTAMP WITH TIME ZONE,
    
    -- Marketplace sharing
    shared_to_marketplace BOOLEAN DEFAULT false,
    marketplace_listing_id UUID REFERENCES marketplace_listings(id),
    sharing_permissions JSONB DEFAULT '{"allow_derivatives": false, "commercial_use": false}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================================
-- PHASE 2: PROMPT TEMPLATES AND COMMUNITY FEATURES
-- ========================================================================

-- Reusable Prompt Templates for Community Sharing
CREATE TABLE IF NOT EXISTS ai_prompt_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Creator information
    creator_id UUID REFERENCES core.users(id), -- NULL for system templates
    creator_type VARCHAR(20) DEFAULT 'parent' CHECK (creator_type IN ('parent', 'educator', 'admin', 'community')),
    
    -- Template content and metadata
    name VARCHAR(255) NOT NULL,
    description TEXT,
    base_prompt TEXT NOT NULL CHECK (length(base_prompt) >= 50),
    
    -- Customization system
    variable_slots JSONB DEFAULT '[]', -- [{"name": "character_name", "type": "text", "required": true, "description": "Main character name"}]
    example_generations JSONB, -- Sample stories created with this template
    
    -- Categorization and targeting
    age_groups VARCHAR(10)[] DEFAULT '{}' CHECK (array_length(age_groups, 1) > 0),
    reading_levels VARCHAR(20)[] DEFAULT '{}',
    story_genres VARCHAR(50)[] DEFAULT '{}', -- adventure, educational, fantasy, etc.
    educational_topics TEXT[] DEFAULT '{}', -- math, science, social skills, etc.
    themes TEXT[] DEFAULT '{}', -- friendship, courage, problem-solving, etc.
    
    -- Community and marketplace features
    is_public BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false, -- Platform-verified quality
    
    -- Usage and performance tracking
    usage_count INTEGER DEFAULT 0 CHECK (usage_count >= 0),
    successful_generation_rate DECIMAL(5,2) DEFAULT 0.00 CHECK (successful_generation_rate >= 0.00 AND successful_generation_rate <= 100.00),
    average_parent_rating DECIMAL(3,2) DEFAULT 0.00 CHECK (average_parent_rating >= 0.00 AND average_parent_rating <= 5.00),
    last_used_at TIMESTAMP WITH TIME ZONE,
    
    -- Monetization
    is_premium BOOLEAN DEFAULT false,
    pricing_model VARCHAR(20) DEFAULT 'free' CHECK (pricing_model IN ('free', 'one_time', 'usage_based', 'subscription')),
    price DECIMAL(10,2) DEFAULT 0.00 CHECK (price >= 0.00),
    usage_price DECIMAL(10,4) DEFAULT 0.00 CHECK (usage_price >= 0.00), -- Per generation
    
    -- Revenue sharing for derivatives
    allows_derivatives BOOLEAN DEFAULT false,
    derivative_fee_percentage DECIMAL(5,2) DEFAULT 0.00 CHECK (derivative_fee_percentage >= 0.00 AND derivative_fee_percentage <= 50.00),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Template Usage Tracking for Analytics
CREATE TABLE IF NOT EXISTS ai_template_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES ai_prompt_templates(id),
    generation_id UUID NOT NULL REFERENCES ai_story_generations(id),
    user_id UUID NOT NULL REFERENCES core.users(id),
    
    -- Usage details
    customization_values JSONB, -- Values used for template variables
    generation_successful BOOLEAN,
    parent_approved BOOLEAN,
    shared_to_marketplace BOOLEAN DEFAULT false,
    
    -- Revenue tracking (if premium template)
    amount_paid DECIMAL(10,2) DEFAULT 0.00,
    creator_earnings DECIMAL(10,2) DEFAULT 0.00,
    platform_fee DECIMAL(10,2) DEFAULT 0.00,
    
    used_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================================
-- PHASE 3: CREATOR ECONOMY AND COLLABORATION
-- ========================================================================

-- Creator Profiles and Community Features
CREATE TABLE IF NOT EXISTS creator_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES core.users(id) UNIQUE,
    
    -- Public profile information
    display_name VARCHAR(100) NOT NULL,
    bio TEXT,
    specialties TEXT[] DEFAULT '{}', -- bedtime stories, educational, adventure, etc.
    
    -- Creator verification and badges
    is_verified BOOLEAN DEFAULT false,
    verification_type VARCHAR(50), -- 'educator', 'author', 'platform_champion', etc.
    badges TEXT[] DEFAULT '{}', -- achievement badges
    
    -- Creator stats (automatically calculated)
    total_stories_created INTEGER DEFAULT 0,
    total_templates_created INTEGER DEFAULT 0,
    total_earnings DECIMAL(10,2) DEFAULT 0.00,
    average_story_rating DECIMAL(3,2) DEFAULT 0.00,
    total_downloads INTEGER DEFAULT 0,
    
    -- Creator preferences
    content_creation_methods TEXT[] DEFAULT '{}', -- 'ai_assisted', 'human_only', 'collaborative'
    preferred_age_groups VARCHAR(10)[] DEFAULT '{}',
    preferred_genres TEXT[] DEFAULT '{}',
    
    -- Social features
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    
    -- Marketplace settings
    accepts_collaborations BOOLEAN DEFAULT false,
    commission_rate DECIMAL(5,2) DEFAULT 0.00, -- For custom work
    payment_info JSONB, -- Encrypted payment details
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Creator Following System
CREATE TABLE IF NOT EXISTS creator_follows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES core.users(id),
    following_creator_id UUID NOT NULL REFERENCES creator_profiles(id),
    
    followed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(follower_id, following_creator_id)
);

-- Collaborative Story Projects
CREATE TABLE IF NOT EXISTS collaborative_stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Project metadata
    title VARCHAR(255) NOT NULL,
    description TEXT,
    project_status VARCHAR(20) DEFAULT 'active' CHECK (project_status IN ('planning', 'active', 'completed', 'abandoned')),
    
    -- Collaboration settings
    is_public BOOLEAN DEFAULT false, -- Others can join
    max_collaborators INTEGER DEFAULT 5,
    collaboration_type VARCHAR(20) DEFAULT 'open' CHECK (collaboration_type IN ('open', 'invite_only', 'curated')),
    
    -- Target story parameters
    target_age_groups VARCHAR(10)[] NOT NULL,
    target_themes TEXT[],
    estimated_pages INTEGER,
    
    -- Project ownership
    created_by UUID NOT NULL REFERENCES creator_profiles(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Collaborator Participation in Projects
CREATE TABLE IF NOT EXISTS story_collaborators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES collaborative_stories(id),
    collaborator_id UUID NOT NULL REFERENCES creator_profiles(id),
    
    -- Collaboration role and permissions
    role VARCHAR(20) DEFAULT 'contributor' CHECK (role IN ('owner', 'editor', 'contributor', 'reviewer')),
    permissions JSONB DEFAULT '{"can_edit": true, "can_invite": false, "can_publish": false}',
    
    -- Contribution tracking
    contribution_percentage DECIMAL(5,2) DEFAULT 0.00,
    contribution_type TEXT[] DEFAULT '{}', -- 'writing', 'editing', 'concept', 'images'
    
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_contribution_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(project_id, collaborator_id)
);

-- ========================================================================
-- PHASE 4: LIBRARY SYSTEM AND PERSONALIZATION
-- ========================================================================

-- Personal Story Collections (Child's Curated Library)
CREATE TABLE IF NOT EXISTS personal_story_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Collection ownership
    child_id UUID NOT NULL REFERENCES family.child_profiles(id),
    parent_id UUID NOT NULL REFERENCES core.users(id), -- Parent who manages the collection
    
    -- Collection metadata
    name VARCHAR(255) NOT NULL,
    description TEXT,
    collection_type VARCHAR(50) DEFAULT 'custom' CHECK (collection_type IN (
        'custom', 'favorites', 'bedtime', 'learning', 'adventures', 'ai_generated', 
        'purchased', 'shared', 'seasonal', 'milestone'
    )),
    
    -- Visual customization
    cover_image_id UUID REFERENCES core.uploaded_files(id),
    theme_color VARCHAR(7), -- Hex color code
    icon VARCHAR(50), -- Icon identifier
    
    -- Collection settings
    is_private BOOLEAN DEFAULT true,
    auto_add_criteria JSONB, -- Automatic addition rules
    sort_order VARCHAR(20) DEFAULT 'date_added' CHECK (sort_order IN ('date_added', 'alphabetical', 'reading_level', 'custom')),
    
    -- Usage tracking
    stories_count INTEGER DEFAULT 0,
    last_accessed_at TIMESTAMP WITH TIME ZONE,
    total_reading_time INTEGER DEFAULT 0, -- in seconds
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Stories within Collections
CREATE TABLE IF NOT EXISTS collection_stories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES personal_story_collections(id),
    story_template_id UUID NOT NULL REFERENCES story_templates(id),
    
    -- Position and customization within collection
    sort_position INTEGER DEFAULT 0,
    custom_notes TEXT, -- Parent or child notes about this story
    tags TEXT[] DEFAULT '{}', -- Custom tags for this story in this collection
    
    -- Reading progress specific to this collection context
    reading_progress DECIMAL(5,2) DEFAULT 0.00, -- Percentage complete
    last_read_at TIMESTAMP WITH TIME ZONE,
    reading_sessions INTEGER DEFAULT 0,
    
    added_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    added_by UUID REFERENCES core.users(id), -- Parent or system
    
    UNIQUE(collection_id, story_template_id)
);

-- Child Reading Recommendations and Personalization
CREATE TABLE IF NOT EXISTS reading_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES family.child_profiles(id),
    story_template_id UUID NOT NULL REFERENCES story_templates(id),
    
    -- Recommendation source and reasoning
    recommendation_type VARCHAR(50) NOT NULL CHECK (recommendation_type IN (
        'similar_content', 'reading_level', 'interests', 'popular_with_peers', 
        'educational_goals', 'creator_follow', 'seasonal', 'milestone_based'
    )),
    recommendation_score DECIMAL(5,2) NOT NULL CHECK (recommendation_score >= 0.00 AND recommendation_score <= 100.00),
    recommendation_reasons JSONB, -- Detailed explanation of why recommended
    
    -- Interaction tracking
    shown_to_parent BOOLEAN DEFAULT false,
    shown_to_child BOOLEAN DEFAULT false,
    clicked BOOLEAN DEFAULT false,
    started_reading BOOLEAN DEFAULT false,
    completed_reading BOOLEAN DEFAULT false,
    
    -- Feedback
    parent_feedback VARCHAR(20), -- 'helpful', 'not_relevant', 'inappropriate'
    child_engagement_score DECIMAL(3,2), -- Derived from reading behavior
    
    -- Lifecycle
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '30 days'),
    first_shown_at TIMESTAMP WITH TIME ZONE,
    last_interaction_at TIMESTAMP WITH TIME ZONE
);

-- ========================================================================
-- EXTEND EXISTING TABLES
-- ========================================================================

-- Extend story_templates with AI and marketplace metadata
DO $$ 
BEGIN
    -- Add AI generation metadata
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='story_templates' AND column_name='creator_type') THEN
        ALTER TABLE story_templates ADD COLUMN creator_type VARCHAR(20) DEFAULT 'human' CHECK (creator_type IN ('human', 'ai_assisted', 'fully_ai'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='story_templates' AND column_name='ai_generation_id') THEN
        ALTER TABLE story_templates ADD COLUMN ai_generation_id UUID REFERENCES ai_story_generations(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='story_templates' AND column_name='source_prompt') THEN
        ALTER TABLE story_templates ADD COLUMN source_prompt TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='story_templates' AND column_name='generation_metadata') THEN
        ALTER TABLE story_templates ADD COLUMN generation_metadata JSONB DEFAULT '{}';
    END IF;
    
    -- Add creator economy features
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='story_templates' AND column_name='creator_profile_id') THEN
        ALTER TABLE story_templates ADD COLUMN creator_profile_id UUID REFERENCES creator_profiles(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='story_templates' AND column_name='collaboration_id') THEN
        ALTER TABLE story_templates ADD COLUMN collaboration_id UUID REFERENCES collaborative_stories(id);
    END IF;
    
    -- Add library and discovery features
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='story_templates' AND column_name='educational_standards') THEN
        ALTER TABLE story_templates ADD COLUMN educational_standards JSONB DEFAULT '{}'; -- Curriculum alignment data
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='story_templates' AND column_name='content_tags') THEN
        ALTER TABLE story_templates ADD COLUMN content_tags TEXT[] DEFAULT '{}'; -- Searchable content tags
    END IF;
END $$;

-- Extend marketplace_listings for AI content and creator economy
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='marketplace_listings' AND column_name='content_source') THEN
        ALTER TABLE marketplace_listings ADD COLUMN content_source VARCHAR(20) DEFAULT 'human' CHECK (content_source IN ('human', 'ai_generated', 'ai_assisted', 'collaborative'));
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='marketplace_listings' AND column_name='prompt_template_id') THEN
        ALTER TABLE marketplace_listings ADD COLUMN prompt_template_id UUID REFERENCES ai_prompt_templates(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='marketplace_listings' AND column_name='creator_profile_id') THEN
        ALTER TABLE marketplace_listings ADD COLUMN creator_profile_id UUID REFERENCES creator_profiles(id);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='marketplace_listings' AND column_name='allows_derivatives') THEN
        ALTER TABLE marketplace_listings ADD COLUMN allows_derivatives BOOLEAN DEFAULT false;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='marketplace_listings' AND column_name='derivative_fee_percentage') THEN
        ALTER TABLE marketplace_listings ADD COLUMN derivative_fee_percentage DECIMAL(5,2) DEFAULT 0.00 CHECK (derivative_fee_percentage >= 0.00 AND derivative_fee_percentage <= 50.00);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='marketplace_listings' AND column_name='collaboration_revenue_sharing') THEN
        ALTER TABLE marketplace_listings ADD COLUMN collaboration_revenue_sharing JSONB DEFAULT '{}'; -- Revenue split for collaborative works
    END IF;
END $$;

-- Extend uploaded_files with AI image analysis
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='uploaded_files' AND column_name='ai_analysis') THEN
        ALTER TABLE core.uploaded_files ADD COLUMN ai_analysis JSONB DEFAULT '{}';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='uploaded_files' AND column_name='detected_objects') THEN
        ALTER TABLE core.uploaded_files ADD COLUMN detected_objects TEXT[] DEFAULT '{}';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='uploaded_files' AND column_name='scene_description') THEN
        ALTER TABLE core.uploaded_files ADD COLUMN scene_description TEXT;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='uploaded_files' AND column_name='is_character') THEN
        ALTER TABLE core.uploaded_files ADD COLUMN is_character BOOLEAN DEFAULT false;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='uploaded_files' AND column_name='is_background') THEN
        ALTER TABLE core.uploaded_files ADD COLUMN is_background BOOLEAN DEFAULT false;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='uploaded_files' AND column_name='is_child_safe') THEN
        ALTER TABLE core.uploaded_files ADD COLUMN is_child_safe BOOLEAN DEFAULT true;
    END IF;
END $$;

-- ========================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- ========================================================================

-- AI Generation System Indexes
CREATE INDEX IF NOT EXISTS idx_ai_generations_parent_status ON ai_story_generations(parent_id, status);
CREATE INDEX IF NOT EXISTS idx_ai_generations_created_at ON ai_story_generations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_generations_child_id ON ai_story_generations(child_id) WHERE child_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ai_generations_provider ON ai_story_generations(provider_used, status);

CREATE INDEX IF NOT EXISTS idx_ai_generated_stories_approval ON ai_generated_stories(approval_status, created_at);
CREATE INDEX IF NOT EXISTS idx_ai_generated_stories_template ON ai_generated_stories(story_template_id) WHERE story_template_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ai_generated_stories_marketplace ON ai_generated_stories(shared_to_marketplace) WHERE shared_to_marketplace = true;

CREATE INDEX IF NOT EXISTS idx_generation_quotas_user ON ai_generation_quotas(user_id);
CREATE INDEX IF NOT EXISTS idx_generation_quotas_tier ON ai_generation_quotas(subscription_tier, daily_used);

-- Prompt Templates and Community Indexes
CREATE INDEX IF NOT EXISTS idx_prompt_templates_public ON ai_prompt_templates(is_public, average_parent_rating DESC) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_prompt_templates_creator ON ai_prompt_templates(creator_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_prompt_templates_usage ON ai_prompt_templates(usage_count DESC) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_prompt_templates_age_genre ON ai_prompt_templates USING GIN(age_groups, story_genres) WHERE is_public = true;

CREATE INDEX IF NOT EXISTS idx_template_usage_template ON ai_template_usage(template_id, used_at DESC);
CREATE INDEX IF NOT EXISTS idx_template_usage_user ON ai_template_usage(user_id, used_at DESC);

-- Creator Economy Indexes
CREATE INDEX IF NOT EXISTS idx_creator_profiles_verified ON creator_profiles(is_verified, total_earnings DESC) WHERE is_verified = true;
CREATE INDEX IF NOT EXISTS idx_creator_profiles_stats ON creator_profiles(average_story_rating DESC, total_downloads DESC);
CREATE INDEX IF NOT EXISTS idx_creator_follows_follower ON creator_follows(follower_id, followed_at DESC);
CREATE INDEX IF NOT EXISTS idx_creator_follows_creator ON creator_follows(following_creator_id, followed_at DESC);

CREATE INDEX IF NOT EXISTS idx_collaborative_stories_status ON collaborative_stories(project_status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_collaborative_stories_creator ON collaborative_stories(created_by, project_status);
CREATE INDEX IF NOT EXISTS idx_story_collaborators_project ON story_collaborators(project_id, role);

-- Library System Indexes
CREATE INDEX IF NOT EXISTS idx_story_collections_child ON personal_story_collections(child_id, collection_type);
CREATE INDEX IF NOT EXISTS idx_story_collections_parent ON personal_story_collections(parent_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_collection_stories_collection ON collection_stories(collection_id, sort_position);
CREATE INDEX IF NOT EXISTS idx_collection_stories_template ON collection_stories(story_template_id);

CREATE INDEX IF NOT EXISTS idx_recommendations_child ON reading_recommendations(child_id, recommendation_score DESC) WHERE expires_at > CURRENT_TIMESTAMP;
CREATE INDEX IF NOT EXISTS idx_recommendations_type ON reading_recommendations(recommendation_type, generated_at DESC);

-- Extended Table Indexes
CREATE INDEX IF NOT EXISTS idx_story_templates_creator_type ON story_templates(creator_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_story_templates_ai_generation ON story_templates(ai_generation_id) WHERE ai_generation_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_story_templates_creator_profile ON story_templates(creator_profile_id) WHERE creator_profile_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_story_templates_content_tags ON story_templates USING GIN(content_tags);

CREATE INDEX IF NOT EXISTS idx_marketplace_content_source ON marketplace_listings(content_source, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_marketplace_creator_profile ON marketplace_listings(creator_profile_id) WHERE creator_profile_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_marketplace_derivatives ON marketplace_listings(allows_derivatives) WHERE allows_derivatives = true;

CREATE INDEX IF NOT EXISTS idx_uploaded_files_analysis ON core.uploaded_files USING GIN(ai_analysis) WHERE ai_analysis != '{}';
CREATE INDEX IF NOT EXISTS idx_uploaded_files_character ON core.uploaded_files(is_character, is_child_safe) WHERE is_character = true;

-- ========================================================================
-- DEFAULT DATA AND CONFIGURATION
-- ========================================================================

-- Insert default AI generation configuration
INSERT INTO ai_generation_config (provider_name, model_name, is_primary) 
VALUES ('gemini', 'gemini-1.5-flash', true)
ON CONFLICT DO NOTHING;

-- Insert system prompt templates
INSERT INTO ai_prompt_templates (
    creator_id, creator_type, name, description, base_prompt, 
    age_groups, story_genres, is_public, is_featured
) VALUES 
(NULL, 'admin', 'Adventure Template', 'A basic adventure story template', 
 'Create an exciting adventure story about {character} who goes on a quest to {destination}. The story should teach about {lesson} and be appropriate for {age_group} children.',
 ARRAY['6-8', '9-12'], ARRAY['adventure'], true, true),
 
(NULL, 'admin', 'Bedtime Story Template', 'Calming bedtime story template',
 'Write a gentle bedtime story featuring {character} in a peaceful {setting}. The story should help children feel calm and ready for sleep, with themes of {comfort_theme}.',
 ARRAY['3-5', '6-8'], ARRAY['bedtime'], true, true),
 
(NULL, 'admin', 'Educational Template', 'Learning-focused story template',
 'Create an educational story that teaches {subject} through the adventures of {character}. Include specific concepts about {learning_objective} in an age-appropriate way.',
 ARRAY['6-8', '9-12'], ARRAY['educational'], true, true)
ON CONFLICT DO NOTHING;

-- ========================================================================
-- VIEWS FOR COMMON QUERIES
-- ========================================================================

-- Creator performance summary view
CREATE OR REPLACE VIEW creator_performance_summary AS
SELECT 
    cp.id as creator_profile_id,
    cp.user_id,
    cp.display_name,
    cp.is_verified,
    cp.total_stories_created,
    cp.total_templates_created,
    cp.total_earnings,
    cp.average_story_rating,
    cp.followers_count,
    
    -- Recent activity metrics
    COUNT(DISTINCT st.id) FILTER (WHERE st.created_at > CURRENT_TIMESTAMP - INTERVAL '30 days') as stories_last_30_days,
    COUNT(DISTINCT apt.id) FILTER (WHERE apt.created_at > CURRENT_TIMESTAMP - INTERVAL '30 days') as templates_last_30_days,
    
    -- Marketplace performance
    COUNT(DISTINCT ml.id) as marketplace_listings,
    COALESCE(SUM(sp.price_paid), 0) as total_sales,
    
    -- Template usage
    COUNT(DISTINCT atu.id) as template_uses,
    AVG(apt.successful_generation_rate) as avg_template_success_rate

FROM creator_profiles cp
LEFT JOIN story_templates st ON st.creator_profile_id = cp.id
LEFT JOIN ai_prompt_templates apt ON apt.creator_id = cp.user_id
LEFT JOIN marketplace_listings ml ON ml.creator_profile_id = cp.id
LEFT JOIN story_purchases sp ON sp.listing_id = ml.id
LEFT JOIN ai_template_usage atu ON atu.template_id = apt.id

GROUP BY cp.id, cp.user_id, cp.display_name, cp.is_verified, 
         cp.total_stories_created, cp.total_templates_created, 
         cp.total_earnings, cp.average_story_rating, cp.followers_count;

-- Child library summary view
CREATE OR REPLACE VIEW child_library_summary AS
SELECT 
    cp.id as child_id,
    cp.first_name,
    
    -- Collection counts
    COUNT(DISTINCT psc.id) as total_collections,
    COUNT(DISTINCT cs.story_template_id) as total_stories_in_collections,
    
    -- Reading progress
    AVG(cs.reading_progress) as average_reading_progress,
    COUNT(DISTINCT cs.id) FILTER (WHERE cs.reading_progress = 100) as completed_stories,
    COUNT(DISTINCT cs.id) FILTER (WHERE cs.last_read_at > CURRENT_TIMESTAMP - INTERVAL '7 days') as stories_read_last_week,
    
    -- Story sources
    COUNT(DISTINCT cs.story_template_id) FILTER (WHERE st.creator_type = 'fully_ai') as ai_generated_stories,
    COUNT(DISTINCT cs.story_template_id) FILTER (WHERE st.creator_type = 'human') as human_created_stories,
    COUNT(DISTINCT cs.story_template_id) FILTER (WHERE st.creator_type = 'ai_assisted') as ai_assisted_stories,
    
    -- Recent recommendations
    COUNT(DISTINCT rr.id) FILTER (WHERE rr.expires_at > CURRENT_TIMESTAMP) as active_recommendations

FROM family.child_profiles cp
LEFT JOIN personal_story_collections psc ON psc.child_id = cp.id
LEFT JOIN collection_stories cs ON cs.collection_id = psc.id
LEFT JOIN story_templates st ON st.id = cs.story_template_id
LEFT JOIN reading_recommendations rr ON rr.child_id = cp.id

GROUP BY cp.id, cp.first_name;

-- Platform health metrics view
CREATE OR REPLACE VIEW platform_health_metrics AS
SELECT 
    -- AI generation metrics
    COUNT(DISTINCT asg.id) FILTER (WHERE asg.created_at > CURRENT_TIMESTAMP - INTERVAL '24 hours') as generations_last_24h,
    COUNT(DISTINCT asg.id) FILTER (WHERE asg.created_at > CURRENT_TIMESTAMP - INTERVAL '24 hours' AND asg.status = 'completed') as successful_generations_last_24h,
    
    -- Content creation metrics
    COUNT(DISTINCT st.id) FILTER (WHERE st.created_at > CURRENT_TIMESTAMP - INTERVAL '7 days') as new_stories_last_week,
    COUNT(DISTINCT apt.id) FILTER (WHERE apt.created_at > CURRENT_TIMESTAMP - INTERVAL '7 days') as new_templates_last_week,
    
    -- Community metrics
    COUNT(DISTINCT cp.id) FILTER (WHERE cp.created_at > CURRENT_TIMESTAMP - INTERVAL '30 days') as new_creators_last_month,
    COUNT(DISTINCT ml.id) FILTER (WHERE ml.created_at > CURRENT_TIMESTAMP - INTERVAL '7 days') as new_marketplace_listings_last_week,
    
    -- Revenue metrics
    SUM(sp.price_paid) FILTER (WHERE sp.purchased_at > CURRENT_TIMESTAMP - INTERVAL '30 days') as revenue_last_30_days,
    COUNT(DISTINCT sp.id) FILTER (WHERE sp.purchased_at > CURRENT_TIMESTAMP - INTERVAL '30 days') as purchases_last_30_days,
    
    -- Safety metrics
    COUNT(DISTINCT asg.id) FILTER (WHERE asg.status = 'moderation_required') as content_requiring_moderation,
    COUNT(DISTINCT ags.id) FILTER (WHERE ags.approval_status = 'rejected') as rejected_stories_total,
    
    -- Current timestamp for reference
    CURRENT_TIMESTAMP as calculated_at

FROM ai_story_generations asg
CROSS JOIN story_templates st
CROSS JOIN ai_prompt_templates apt
CROSS JOIN creator_profiles cp
CROSS JOIN marketplace_listings ml
CROSS JOIN story_purchases sp
CROSS JOIN ai_generated_stories ags;

-- ========================================================================
-- TRIGGERS AND AUTOMATED UPDATES
-- ========================================================================

-- Automatically update creator profile stats
CREATE OR REPLACE FUNCTION update_creator_profile_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Update the creator profile with latest stats
    UPDATE creator_profiles 
    SET 
        total_stories_created = (
            SELECT COUNT(*) FROM story_templates 
            WHERE creator_profile_id = COALESCE(NEW.creator_profile_id, OLD.creator_profile_id)
        ),
        average_story_rating = (
            SELECT COALESCE(AVG(mr.rating), 0) 
            FROM marketplace_listings ml 
            JOIN marketplace_reviews mr ON mr.listing_id = ml.id 
            WHERE ml.creator_profile_id = COALESCE(NEW.creator_profile_id, OLD.creator_profile_id)
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = COALESCE(NEW.creator_profile_id, OLD.creator_profile_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_creator_stats
    AFTER INSERT OR UPDATE OR DELETE ON story_templates
    FOR EACH ROW 
    WHEN (NEW.creator_profile_id IS NOT NULL OR OLD.creator_profile_id IS NOT NULL)
    EXECUTE FUNCTION update_creator_profile_stats();

-- Automatically update template usage stats
CREATE OR REPLACE FUNCTION update_template_usage_stats()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ai_prompt_templates 
    SET 
        usage_count = (SELECT COUNT(*) FROM ai_template_usage WHERE template_id = NEW.template_id),
        successful_generation_rate = (
            SELECT 
                CASE 
                    WHEN COUNT(*) = 0 THEN 0 
                    ELSE (COUNT(*) FILTER (WHERE generation_successful = true) * 100.0 / COUNT(*))::DECIMAL(5,2)
                END
            FROM ai_template_usage 
            WHERE template_id = NEW.template_id
        ),
        last_used_at = NEW.used_at,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = NEW.template_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_template_stats
    AFTER INSERT ON ai_template_usage
    FOR EACH ROW 
    EXECUTE FUNCTION update_template_usage_stats();

-- Reset daily/monthly quotas automatically
CREATE OR REPLACE FUNCTION reset_generation_quotas()
RETURNS void AS $$
BEGIN
    -- Reset daily quotas
    UPDATE ai_generation_quotas 
    SET daily_used = 0, 
        daily_reset_at = date_trunc('day', CURRENT_TIMESTAMP + INTERVAL '1 day')
    WHERE daily_reset_at <= CURRENT_TIMESTAMP;
    
    -- Reset monthly quotas
    UPDATE ai_generation_quotas 
    SET monthly_used = 0,
        monthly_reset_at = date_trunc('month', CURRENT_TIMESTAMP + INTERVAL '1 month')
    WHERE monthly_reset_at <= CURRENT_TIMESTAMP;
END;
$$ LANGUAGE plpgsql;

-- ========================================================================
-- COMMENTS AND DOCUMENTATION
-- ========================================================================

COMMENT ON TABLE ai_generation_config IS 'Configuration for AI/LLM providers and generation parameters';
COMMENT ON TABLE ai_generation_quotas IS 'User quotas and subscription tier limits for AI story generation';
COMMENT ON TABLE ai_story_generations IS 'Tracks all AI story generation requests from input to completion';
COMMENT ON TABLE ai_generated_stories IS 'Links generated stories to approval workflow and marketplace sharing';
COMMENT ON TABLE ai_prompt_templates IS 'Reusable prompt templates for community sharing and marketplace';
COMMENT ON TABLE creator_profiles IS 'Extended user profiles for content creators in the community';
COMMENT ON TABLE collaborative_stories IS 'Multi-creator story projects and collaboration management';
COMMENT ON TABLE personal_story_collections IS 'Child-specific curated collections within their personal library';
COMMENT ON TABLE reading_recommendations IS 'Personalized story recommendations based on child preferences and behavior';

COMMENT ON COLUMN ai_story_generations.safety_check_passed IS 'True if generated content passes all safety and COPPA compliance checks';
COMMENT ON COLUMN ai_generated_stories.approval_status IS 'Parent approval workflow status before child access is granted';
COMMENT ON COLUMN creator_profiles.is_verified IS 'Platform-verified creator status (educator, published author, etc.)';
COMMENT ON COLUMN personal_story_collections.auto_add_criteria IS 'JSON rules for automatically adding stories to collection';

-- ========================================================================
-- MIGRATION COMPLETION
-- ========================================================================

-- Update schema version to track this migration
INSERT INTO schema_migrations (version, applied_at) VALUES ('ai_story_platform_consolidated_v1.0', CURRENT_TIMESTAMP)
ON CONFLICT (version) DO UPDATE SET applied_at = CURRENT_TIMESTAMP;

-- Analyze tables for query optimization
ANALYZE ai_generation_config;
ANALYZE ai_generation_quotas;
ANALYZE ai_story_generations;
ANALYZE ai_generated_stories;
ANALYZE ai_prompt_templates;
ANALYZE creator_profiles;
ANALYZE collaborative_stories;
ANALYZE personal_story_collections;
ANALYZE reading_recommendations;

SELECT 'Integrated AI Story Platform database migration completed successfully' AS result;