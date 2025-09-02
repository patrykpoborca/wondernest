-- =============================================================================
-- WonderNest AI Story Generator Database Migration
-- Extends existing story and marketplace infrastructure with AI capabilities
-- =============================================================================

-- Switch to games schema where story tables exist
SET search_path TO games, public;

-- =============================================================================
-- PHASE 1: CORE AI GENERATION TABLES
-- =============================================================================

-- AI generation configuration and tracking
CREATE TABLE IF NOT EXISTS ai_generation_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Provider configuration
    provider VARCHAR(50) NOT NULL DEFAULT 'openai' CHECK (provider IN (
        'openai', 
        'anthropic', 
        'gemini', 
        'local_llm',
        'mock' -- For testing
    )),
    model_name VARCHAR(100) NOT NULL DEFAULT 'gpt-4',
    api_endpoint TEXT,
    api_key_encrypted TEXT, -- Encrypted in application layer
    
    -- Generation parameters
    temperature DECIMAL(3,2) DEFAULT 0.7 CHECK (temperature >= 0 AND temperature <= 2),
    max_tokens INTEGER DEFAULT 2000 CHECK (max_tokens > 0 AND max_tokens <= 10000),
    top_p DECIMAL(3,2) DEFAULT 0.9 CHECK (top_p >= 0 AND top_p <= 1),
    
    -- Safety and content filters
    content_filters JSONB DEFAULT '{
        "violence": "strict",
        "scary": "moderate", 
        "educational": "required",
        "age_appropriate": true,
        "vocabulary_level": "auto"
    }',
    
    -- Rate limiting per family
    daily_generation_limit INTEGER DEFAULT 10,
    monthly_generation_limit INTEGER DEFAULT 100,
    
    -- Cost management
    cost_per_1k_tokens DECIMAL(10,4) DEFAULT 0.03,
    monthly_budget_limit DECIMAL(10,2) DEFAULT 50.00,
    
    -- Feature flags
    allow_custom_characters BOOLEAN DEFAULT true,
    allow_image_generation BOOLEAN DEFAULT false,
    allow_voice_generation BOOLEAN DEFAULT false,
    require_parent_approval BOOLEAN DEFAULT true,
    auto_translate BOOLEAN DEFAULT false,
    
    -- Configuration metadata
    is_active BOOLEAN DEFAULT true,
    is_default BOOLEAN DEFAULT false,
    config_name VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- AI generation requests tracking
CREATE TABLE IF NOT EXISTS ai_story_generations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Requester information
    parent_id UUID NOT NULL, -- References core.users(id)
    family_id UUID NOT NULL, -- References family.families(id)
    child_id UUID, -- References family.child_profiles(id)
    
    -- Generation configuration
    config_id UUID REFERENCES ai_generation_config(id),
    
    -- Generation input
    prompt TEXT NOT NULL,
    prompt_template_id UUID, -- References ai_prompt_templates(id)
    selected_image_ids UUID[] DEFAULT '{}', -- References core.uploaded_files
    
    -- Generation parameters (override config defaults)
    generation_params JSONB DEFAULT '{
        "age_group": null,
        "difficulty": null,
        "page_count": null,
        "vocabulary_focus": [],
        "themes": [],
        "character_names": {},
        "setting": null,
        "moral_lesson": null
    }',
    
    -- Generation output
    generated_template_id UUID, -- References story_templates(id)
    generation_status VARCHAR(50) DEFAULT 'pending' CHECK (generation_status IN (
        'pending',
        'validating_input',
        'analyzing_images',
        'generating',
        'post_processing',
        'moderating',
        'completed',
        'failed',
        'rejected_safety',
        'rejected_parent',
        'timeout'
    )),
    
    -- LLM interaction details
    llm_provider VARCHAR(50),
    llm_model VARCHAR(100),
    llm_request_id VARCHAR(255), -- External API request ID
    llm_request JSONB, -- Full request for debugging
    llm_response JSONB, -- Full response
    
    -- Token and cost tracking
    prompt_tokens INTEGER,
    completion_tokens INTEGER,
    total_tokens INTEGER,
    generation_cost DECIMAL(10,4),
    
    -- Image analysis results (if images provided)
    image_analysis JSONB DEFAULT '[]', -- Array of analysis per image
    
    -- Safety check results
    safety_check JSONB DEFAULT '{
        "passed": null,
        "concerns": [],
        "modifications": []
    }',
    
    -- Timing metrics
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    generation_time_ms INTEGER,
    image_analysis_time_ms INTEGER,
    total_time_ms INTEGER,
    
    -- Error handling
    error_code VARCHAR(50),
    error_message TEXT,
    error_details JSONB,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    
    -- Parent review
    parent_approved BOOLEAN,
    parent_feedback TEXT,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Community prompt templates for sharing and marketplace
CREATE TABLE IF NOT EXISTS ai_prompt_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Creator information
    creator_id UUID NOT NULL, -- References core.users(id)
    creator_type VARCHAR(20) DEFAULT 'parent' CHECK (creator_type IN (
        'parent',
        'admin',
        'educator',
        'community'
    )),
    
    -- Template identification
    title VARCHAR(255) NOT NULL,
    description TEXT,
    version VARCHAR(10) DEFAULT '1.0.0',
    
    -- Prompt content
    base_prompt TEXT NOT NULL,
    system_prompt TEXT, -- Additional context for LLM
    
    -- Customization variables
    variable_slots JSONB DEFAULT '[]',
    /* Example:
    [
        {
            "name": "character_name",
            "type": "text",
            "label": "Main Character Name",
            "placeholder": "Enter a name",
            "required": true,
            "default": null
        },
        {
            "name": "favorite_color", 
            "type": "select",
            "label": "Favorite Color",
            "options": ["red", "blue", "green"],
            "required": false,
            "default": "blue"
        }
    ]
    */
    
    -- Template configuration
    suggested_tags TEXT[] DEFAULT '{}',
    required_image_count INTEGER DEFAULT 0,
    optional_image_count INTEGER DEFAULT 5,
    
    -- Target audience
    age_group VARCHAR(10) CHECK (age_group IN ('3-5', '6-8', '9-12')),
    difficulty VARCHAR(20) CHECK (difficulty IN ('emerging', 'developing', 'fluent')),
    
    -- Categorization
    story_type VARCHAR(50), -- 'adventure', 'educational', 'bedtime', 'moral', 'fantasy'
    themes TEXT[] DEFAULT '{}',
    educational_goals TEXT[] DEFAULT '{}',
    
    -- Output configuration
    default_page_count INTEGER DEFAULT 10,
    min_page_count INTEGER DEFAULT 5,
    max_page_count INTEGER DEFAULT 20,
    
    -- Community features
    is_public BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    is_certified BOOLEAN DEFAULT false, -- Verified by admins
    
    -- Usage tracking
    usage_count INTEGER DEFAULT 0,
    successful_generations INTEGER DEFAULT 0,
    failed_generations INTEGER DEFAULT 0,
    
    -- Ratings and feedback
    rating DECIMAL(3,2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
    rating_count INTEGER DEFAULT 0,
    
    -- Marketplace features
    is_premium BOOLEAN DEFAULT false,
    price DECIMAL(10,2) DEFAULT 0.00 CHECK (price >= 0),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Derivative permissions
    allows_derivatives BOOLEAN DEFAULT true,
    derivative_terms TEXT,
    attribution_required BOOLEAN DEFAULT true,
    
    -- Moderation
    moderation_status VARCHAR(20) DEFAULT 'pending' CHECK (moderation_status IN (
        'pending',
        'approved',
        'rejected', 
        'suspended'
    )),
    moderation_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Track usage of prompt templates
CREATE TABLE IF NOT EXISTS ai_prompt_template_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES ai_prompt_templates(id) ON DELETE CASCADE,
    user_id UUID NOT NULL, -- References core.users(id)
    generation_id UUID REFERENCES ai_story_generations(id),
    
    -- Usage details
    variables_used JSONB DEFAULT '{}',
    success BOOLEAN DEFAULT true,
    
    -- Feedback
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    feedback TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- PHASE 2: EXTEND EXISTING TABLES
-- =============================================================================

-- Extend story_templates with AI metadata
ALTER TABLE story_templates ADD COLUMN IF NOT EXISTS 
    creator_type VARCHAR(20) DEFAULT 'human' CHECK (creator_type IN (
        'human',
        'ai_assisted',
        'fully_ai'
    ));

ALTER TABLE story_templates ADD COLUMN IF NOT EXISTS
    ai_generation_id UUID REFERENCES ai_story_generations(id);

ALTER TABLE story_templates ADD COLUMN IF NOT EXISTS
    source_prompt TEXT;

ALTER TABLE story_templates ADD COLUMN IF NOT EXISTS
    generation_params JSONB;

ALTER TABLE story_templates ADD COLUMN IF NOT EXISTS
    parent_template_id UUID REFERENCES story_templates(id);

ALTER TABLE story_templates ADD COLUMN IF NOT EXISTS
    is_ai_editable BOOLEAN DEFAULT false;

ALTER TABLE story_templates ADD COLUMN IF NOT EXISTS
    ai_metadata JSONB DEFAULT '{}';

-- Extend marketplace_listings for AI content
ALTER TABLE marketplace_listings ADD COLUMN IF NOT EXISTS
    content_source VARCHAR(20) DEFAULT 'human' CHECK (content_source IN (
        'human',
        'ai_generated',
        'ai_assisted',
        'ai_enhanced'
    ));

ALTER TABLE marketplace_listings ADD COLUMN IF NOT EXISTS
    allows_derivatives BOOLEAN DEFAULT false;

ALTER TABLE marketplace_listings ADD COLUMN IF NOT EXISTS
    derivative_fee_percentage DECIMAL(5,2) DEFAULT 0.00 CHECK (
        derivative_fee_percentage >= 0 AND derivative_fee_percentage <= 100
    );

ALTER TABLE marketplace_listings ADD COLUMN IF NOT EXISTS
    prompt_template_id UUID REFERENCES ai_prompt_templates(id);

ALTER TABLE marketplace_listings ADD COLUMN IF NOT EXISTS
    original_creator_id UUID; -- For tracking derivative works

-- Add AI analysis to uploaded files (in core schema)
ALTER TABLE core.uploaded_files ADD COLUMN IF NOT EXISTS
    ai_analysis JSONB DEFAULT '{}';

ALTER TABLE core.uploaded_files ADD COLUMN IF NOT EXISTS
    detected_objects TEXT[] DEFAULT '{}';

ALTER TABLE core.uploaded_files ADD COLUMN IF NOT EXISTS
    detected_colors TEXT[] DEFAULT '{}';

ALTER TABLE core.uploaded_files ADD COLUMN IF NOT EXISTS
    scene_description TEXT;

ALTER TABLE core.uploaded_files ADD COLUMN IF NOT EXISTS
    is_child_safe BOOLEAN DEFAULT true;

ALTER TABLE core.uploaded_files ADD COLUMN IF NOT EXISTS
    ai_analysis_version VARCHAR(10);

ALTER TABLE core.uploaded_files ADD COLUMN IF NOT EXISTS
    analyzed_at TIMESTAMP WITH TIME ZONE;

-- =============================================================================
-- PHASE 3: DERIVATIVE WORKS AND ATTRIBUTION
-- =============================================================================

-- Track derivative relationships between stories
CREATE TABLE IF NOT EXISTS story_derivatives (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Story relationship
    original_story_id UUID NOT NULL REFERENCES story_templates(id),
    derivative_story_id UUID NOT NULL REFERENCES story_templates(id),
    
    -- Creator information
    original_creator_id UUID NOT NULL, -- References core.users(id)
    derivative_creator_id UUID NOT NULL, -- References core.users(id)
    
    -- Derivative details
    derivative_type VARCHAR(50) CHECK (derivative_type IN (
        'translation',
        'adaptation',
        'sequel',
        'prequel',
        'remix',
        'personalization',
        'educational_variant'
    )),
    
    -- Changes made
    changes_description TEXT,
    similarity_percentage DECIMAL(5,2), -- AI-calculated similarity
    
    -- Revenue sharing
    revenue_share_percentage DECIMAL(5,2) DEFAULT 0.00,
    revenue_shared_total DECIMAL(10,2) DEFAULT 0.00,
    
    -- Attribution
    attribution_text TEXT,
    attribution_displayed BOOLEAN DEFAULT true,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(original_story_id, derivative_story_id)
);

-- =============================================================================
-- PHASE 4: ANALYTICS AND METRICS
-- =============================================================================

-- AI generation metrics for monitoring and optimization
CREATE TABLE IF NOT EXISTS ai_generation_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Time window
    metric_date DATE NOT NULL,
    metric_hour INTEGER, -- 0-23, null for daily metrics
    
    -- Aggregated metrics
    total_generations INTEGER DEFAULT 0,
    successful_generations INTEGER DEFAULT 0,
    failed_generations INTEGER DEFAULT 0,
    
    -- Performance metrics
    avg_generation_time_ms INTEGER,
    median_generation_time_ms INTEGER,
    p95_generation_time_ms INTEGER,
    
    -- Token usage
    total_tokens_used BIGINT DEFAULT 0,
    avg_tokens_per_generation INTEGER,
    
    -- Cost metrics
    total_cost DECIMAL(10,2) DEFAULT 0.00,
    avg_cost_per_generation DECIMAL(10,4),
    
    -- Provider breakdown
    provider_breakdown JSONB DEFAULT '{}',
    
    -- Error analysis
    error_breakdown JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(metric_date, metric_hour)
);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- AI generation config indexes
CREATE INDEX IF NOT EXISTS idx_ai_config_active ON ai_generation_config(is_active, is_default);

-- AI story generations indexes
CREATE INDEX IF NOT EXISTS idx_ai_generations_parent ON ai_story_generations(parent_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_generations_family ON ai_story_generations(family_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_generations_status ON ai_story_generations(generation_status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_generations_template ON ai_story_generations(generated_template_id);
CREATE INDEX IF NOT EXISTS idx_ai_generations_images ON ai_story_generations USING GIN(selected_image_ids);

-- AI prompt templates indexes
CREATE INDEX IF NOT EXISTS idx_prompt_templates_public ON ai_prompt_templates(is_public, rating DESC) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_prompt_templates_creator ON ai_prompt_templates(creator_id);
CREATE INDEX IF NOT EXISTS idx_prompt_templates_featured ON ai_prompt_templates(is_featured, rating DESC) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_prompt_templates_age ON ai_prompt_templates(age_group, difficulty);
CREATE INDEX IF NOT EXISTS idx_prompt_templates_themes ON ai_prompt_templates USING GIN(themes);

-- Extended story_templates indexes
CREATE INDEX IF NOT EXISTS idx_story_templates_creator_type ON story_templates(creator_type);
CREATE INDEX IF NOT EXISTS idx_story_templates_ai_generation ON story_templates(ai_generation_id);
CREATE INDEX IF NOT EXISTS idx_story_templates_parent ON story_templates(parent_template_id);

-- Story derivatives indexes
CREATE INDEX IF NOT EXISTS idx_derivatives_original ON story_derivatives(original_story_id);
CREATE INDEX IF NOT EXISTS idx_derivatives_derivative ON story_derivatives(derivative_story_id);
CREATE INDEX IF NOT EXISTS idx_derivatives_creators ON story_derivatives(original_creator_id, derivative_creator_id);

-- AI metrics indexes
CREATE INDEX IF NOT EXISTS idx_ai_metrics_date ON ai_generation_metrics(metric_date DESC);
CREATE INDEX IF NOT EXISTS idx_ai_metrics_date_hour ON ai_generation_metrics(metric_date DESC, metric_hour);

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

-- Auto-update updated_at timestamps
CREATE TRIGGER update_ai_config_updated_at
    BEFORE UPDATE ON ai_generation_config
    FOR EACH ROW
    EXECUTE FUNCTION games.update_updated_at();

CREATE TRIGGER update_prompt_templates_updated_at
    BEFORE UPDATE ON ai_prompt_templates
    FOR EACH ROW
    EXECUTE FUNCTION games.update_updated_at();

-- Update usage count when template is used
CREATE OR REPLACE FUNCTION update_template_usage_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.success = true THEN
        UPDATE ai_prompt_templates
        SET 
            usage_count = usage_count + 1,
            successful_generations = successful_generations + 1
        WHERE id = NEW.template_id;
    ELSE
        UPDATE ai_prompt_templates
        SET 
            usage_count = usage_count + 1,
            failed_generations = failed_generations + 1
        WHERE id = NEW.template_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_template_usage
    AFTER INSERT ON ai_prompt_template_usage
    FOR EACH ROW
    EXECUTE FUNCTION update_template_usage_count();

-- =============================================================================
-- SEED DATA FOR INITIAL PROMPT TEMPLATES
-- =============================================================================

INSERT INTO ai_prompt_templates (
    creator_id,
    creator_type,
    title,
    description,
    base_prompt,
    variable_slots,
    age_group,
    difficulty,
    story_type,
    themes,
    is_public,
    is_featured
) VALUES 
(
    '00000000-0000-0000-0000-000000000000'::UUID, -- System user
    'admin',
    'My Adventure Story',
    'Create a personalized adventure story with your child as the hero',
    'Create a {page_count}-page adventure story for a {age}-year-old child named {character_name} who loves {favorite_thing}. The story should be {difficulty} level appropriate and include themes of {themes}.',
    '[
        {"name": "character_name", "type": "text", "label": "Child''s Name", "required": true},
        {"name": "age", "type": "number", "label": "Child''s Age", "required": true, "min": 3, "max": 12},
        {"name": "favorite_thing", "type": "text", "label": "Favorite Thing", "required": true},
        {"name": "page_count", "type": "number", "label": "Number of Pages", "default": 10},
        {"name": "themes", "type": "multiselect", "label": "Story Themes", "options": ["friendship", "courage", "kindness", "discovery"]}
    ]'::JSONB,
    '3-5',
    'emerging',
    'adventure',
    ARRAY['personalized', 'adventure', 'hero journey'],
    true,
    true
),
(
    '00000000-0000-0000-0000-000000000000'::UUID, -- System user
    'admin',
    'Bedtime Calm-Down Story',
    'Generate a soothing bedtime story to help children wind down',
    'Write a calming {page_count}-page bedtime story featuring {animal} characters in a {setting} setting. Include gentle themes of {themes} and end with everyone peacefully going to sleep.',
    '[
        {"name": "animal", "type": "select", "label": "Animal Character", "options": ["bunny", "bear", "owl", "mouse"], "default": "bunny"},
        {"name": "setting", "type": "select", "label": "Story Setting", "options": ["forest", "meadow", "cozy home", "magical garden"], "default": "forest"},
        {"name": "page_count", "type": "number", "label": "Number of Pages", "default": 8},
        {"name": "themes", "type": "multiselect", "label": "Calming Themes", "options": ["comfort", "safety", "dreams", "love"]}
    ]'::JSONB,
    '3-5',
    'emerging',
    'bedtime',
    ARRAY['calming', 'sleep', 'comfort'],
    true,
    true
);

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant permissions to application user
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA games TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA games TO wondernest_app;

-- Grant permissions for core schema modifications
GRANT ALL PRIVILEGES ON core.uploaded_files TO wondernest_app;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE ai_generation_config IS 'Configuration for AI story generation providers and parameters';
COMMENT ON TABLE ai_story_generations IS 'Tracks all AI story generation requests and results';
COMMENT ON TABLE ai_prompt_templates IS 'Community-created prompt templates for story generation';
COMMENT ON TABLE ai_prompt_template_usage IS 'Tracks usage of prompt templates';
COMMENT ON TABLE story_derivatives IS 'Tracks derivative works and attribution relationships';
COMMENT ON TABLE ai_generation_metrics IS 'Aggregated metrics for AI generation monitoring';

COMMENT ON COLUMN story_templates.creator_type IS 'Indicates whether story was human-created, AI-assisted, or fully AI-generated';
COMMENT ON COLUMN story_templates.ai_generation_id IS 'Links to the AI generation request that created this story';
COMMENT ON COLUMN marketplace_listings.content_source IS 'Indicates the creation method of the marketplace content';
COMMENT ON COLUMN marketplace_listings.derivative_fee_percentage IS 'Revenue share percentage for derivative works';

-- =============================================================================
-- END OF MIGRATION
-- =============================================================================