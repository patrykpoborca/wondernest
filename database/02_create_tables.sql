-- WonderNest Table Creation Script
-- Creates all tables with constraints and relationships
--
-- Usage:
--   psql -U postgres -d wondernest_prod -f 02_create_tables.sql
--
-- Prerequisites:
--   - Database and schemas created (01_create_database.sql)
--   - Connected to wondernest_prod database

-- =============================================================================
-- CORE SCHEMA TABLES - User Management & Authentication
-- =============================================================================

-- Users table - Parent accounts and authentication
CREATE TABLE core.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL CONSTRAINT valid_email CHECK (core.is_valid_email(email)),
    email_verified BOOLEAN DEFAULT FALSE NOT NULL,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    password_hash VARCHAR(255), -- Nullable for OAuth-only accounts
    auth_provider core.auth_provider DEFAULT 'email' NOT NULL,
    external_id VARCHAR(255), -- OAuth provider user ID
    
    -- Profile information
    first_name VARCHAR(100),
    last_name VARCHAR(100), 
    phone VARCHAR(20),
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    
    -- Account status and settings
    status core.user_status DEFAULT 'pending_verification' NOT NULL,
    role core.user_role DEFAULT 'parent' NOT NULL,
    
    -- Privacy and notification preferences
    privacy_settings JSONB DEFAULT '{}' NOT NULL,
    notification_preferences JSONB DEFAULT '{"email": true, "push": true, "sms": false}' NOT NULL,
    
    -- MFA settings
    mfa_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    mfa_secret VARCHAR(255),
    backup_codes TEXT[], -- Encrypted backup codes
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_login_at TIMESTAMP WITH TIME ZONE,
    login_count INTEGER DEFAULT 0 NOT NULL,
    
    -- COPPA compliance
    parental_consent_verified BOOLEAN DEFAULT FALSE NOT NULL,
    parental_consent_method VARCHAR(50),
    parental_consent_date TIMESTAMP WITH TIME ZONE,
    
    -- Soft delete
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT users_external_id_provider_unique UNIQUE (external_id, auth_provider)
);

-- User sessions for active login tracking
CREATE TABLE core.user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    device_fingerprint VARCHAR(255),
    user_agent TEXT,
    ip_address INET,
    location_data JSONB, -- Country, region for security
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL
);

-- Password reset tokens
CREATE TABLE core.password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    used BOOLEAN DEFAULT FALSE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- =============================================================================
-- FAMILY SCHEMA TABLES - Family Structure & Child Profiles
-- =============================================================================

-- Families - family group management
CREATE TABLE family.families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL, -- "The Smith Family"
    created_by UUID REFERENCES core.users(id) ON DELETE SET NULL,
    
    -- Family settings
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    family_settings JSONB DEFAULT '{}' NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Family members - relationship between users and families
CREATE TABLE family.family_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID REFERENCES family.families(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE NOT NULL,
    role VARCHAR(50) DEFAULT 'parent' NOT NULL, -- parent, guardian, caregiver
    permissions JSONB DEFAULT '{}' NOT NULL, -- What they can access
    
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    left_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(family_id, user_id) -- User can only be in family once
);

-- Child profiles - comprehensive child information (COPPA compliant)
CREATE TABLE family.child_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID REFERENCES family.families(id) ON DELETE CASCADE NOT NULL,
    
    -- Basic information (minimal for privacy)
    first_name VARCHAR(100) NOT NULL, -- Only first name, no last name
    birth_date DATE NOT NULL,
    gender VARCHAR(20), -- Optional
    
    -- Development information
    primary_language VARCHAR(10) DEFAULT 'en',
    additional_languages VARCHAR(10)[], 
    
    -- Interests and preferences (for content curation)
    interests TEXT[] DEFAULT '{}',
    favorite_characters TEXT[] DEFAULT '{}',
    content_preferences JSONB DEFAULT '{}' NOT NULL,
    
    -- Special needs or development notes
    special_needs TEXT[],
    development_notes TEXT, -- Free text for parents
    receives_intervention BOOLEAN DEFAULT FALSE,
    intervention_type VARCHAR(100),
    
    -- Avatar and customization
    avatar_url VARCHAR(500),
    theme_preferences JSONB DEFAULT '{}' NOT NULL,
    
    -- Privacy settings
    data_sharing_consent BOOLEAN DEFAULT FALSE NOT NULL, -- Parent consent
    research_participation_consent BOOLEAN DEFAULT FALSE NOT NULL,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    archived_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_birth_date CHECK (birth_date <= CURRENT_DATE AND birth_date >= '1900-01-01')
);

-- =============================================================================
-- SUBSCRIPTION SCHEMA TABLES - Billing & Plans
-- =============================================================================

-- Subscription plans available
CREATE TABLE subscription.plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    type subscription.plan_type NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    
    -- Pricing
    price_cents INTEGER NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD' NOT NULL,
    billing_cycle subscription.billing_cycle NOT NULL,
    
    -- Features
    features JSONB NOT NULL, -- Feature flags and limits
    max_children INTEGER DEFAULT 1,
    max_audio_hours_per_month INTEGER,
    
    -- Plan status
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    is_visible BOOLEAN DEFAULT TRUE NOT NULL, -- Show in UI
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- User subscriptions
CREATE TABLE subscription.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE NOT NULL,
    plan_id UUID REFERENCES subscription.plans(id) NOT NULL,
    
    -- Subscription details
    status subscription.subscription_status NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    trial_ends_at TIMESTAMP WITH TIME ZONE,
    current_period_starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
    current_period_ends_at TIMESTAMP WITH TIME ZONE NOT NULL,
    canceled_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    
    -- Billing integration
    stripe_subscription_id VARCHAR(255) UNIQUE,
    stripe_customer_id VARCHAR(255),
    
    -- Usage tracking
    usage_data JSONB DEFAULT '{}' NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Payment transactions
CREATE TABLE subscription.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID REFERENCES subscription.user_subscriptions(id) ON DELETE SET NULL,
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Transaction details
    amount_cents INTEGER NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD' NOT NULL,
    description TEXT,
    status subscription.payment_status NOT NULL,
    
    -- External payment processor
    stripe_payment_intent_id VARCHAR(255),
    stripe_invoice_id VARCHAR(255),
    payment_method_id VARCHAR(255),
    
    -- Timestamps
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    succeeded_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    refunded_at TIMESTAMP WITH TIME ZONE,
    
    failure_reason TEXT,
    metadata JSONB DEFAULT '{}' NOT NULL
);

-- =============================================================================
-- CONTENT SCHEMA TABLES - Content Library & Curation
-- =============================================================================

-- Content categories (hierarchical)
CREATE TABLE content.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id UUID REFERENCES content.categories(id) ON DELETE SET NULL,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    icon_url VARCHAR(500),
    sort_order INTEGER DEFAULT 0,
    
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Content creators/providers
CREATE TABLE content.creators (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    description TEXT,
    website_url VARCHAR(500),
    logo_url VARCHAR(500),
    
    -- Verification status
    is_verified BOOLEAN DEFAULT FALSE NOT NULL,
    verified_at TIMESTAMP WITH TIME ZONE,
    
    -- Contact and legal
    contact_email VARCHAR(255),
    legal_entity VARCHAR(300),
    content_agreement_signed BOOLEAN DEFAULT FALSE NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Main content library
CREATE TABLE content.items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    external_id VARCHAR(255), -- External system identifier
    creator_id UUID REFERENCES content.creators(id) ON DELETE SET NULL,
    
    -- Basic content information
    title VARCHAR(300) NOT NULL,
    description TEXT,
    content_type content.content_type NOT NULL,
    language VARCHAR(10) DEFAULT 'en' NOT NULL,
    
    -- Content URLs and metadata
    primary_url VARCHAR(1000) NOT NULL,
    thumbnail_url VARCHAR(500),
    poster_url VARCHAR(500),
    duration_seconds INTEGER, -- For video/audio content
    file_size_bytes BIGINT,
    
    -- Age and educational targeting
    min_age_months INTEGER NOT NULL CONSTRAINT valid_min_age CHECK (min_age_months >= 0),
    max_age_months INTEGER NOT NULL CONSTRAINT valid_max_age CHECK (max_age_months >= min_age_months),
    educational_goals TEXT[] DEFAULT '{}',
    learning_objectives TEXT[] DEFAULT '{}',
    skills_developed TEXT[] DEFAULT '{}',
    
    -- Content ratings and safety
    safety_score DECIMAL(3,2) DEFAULT 0.0 NOT NULL CONSTRAINT valid_safety_score CHECK (safety_score >= 0 AND safety_score <= 1),
    educational_value_score DECIMAL(3,2) DEFAULT 0.0 NOT NULL CONSTRAINT valid_edu_score CHECK (educational_value_score >= 0 AND educational_value_score <= 1),
    engagement_score DECIMAL(3,2) DEFAULT 0.0 NOT NULL CONSTRAINT valid_engagement_score CHECK (engagement_score >= 0 AND engagement_score <= 1),
    
    -- Review and publication
    status content.content_status DEFAULT 'pending_review' NOT NULL,
    reviewed_by UUID REFERENCES core.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMP WITH TIME ZONE,
    published_at TIMESTAMP WITH TIME ZONE,
    
    -- Metadata and search
    tags TEXT[] DEFAULT '{}',
    keywords TEXT[] DEFAULT '{}',
    metadata JSONB DEFAULT '{}' NOT NULL, -- Additional structured data
    
    -- Analytics
    view_count INTEGER DEFAULT 0 NOT NULL,
    like_count INTEGER DEFAULT 0 NOT NULL,
    share_count INTEGER DEFAULT 0 NOT NULL,
    average_rating DECIMAL(3,2) DEFAULT 0.0,
    total_ratings INTEGER DEFAULT 0 NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    archived_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT content_url_not_empty CHECK (length(trim(primary_url)) > 0),
    CONSTRAINT content_title_not_empty CHECK (length(trim(title)) > 0)
);

-- Content category relationships (many-to-many)
CREATE TABLE content.item_categories (
    content_id UUID REFERENCES content.items(id) ON DELETE CASCADE NOT NULL,
    category_id UUID REFERENCES content.categories(id) ON DELETE CASCADE NOT NULL,
    is_primary BOOLEAN DEFAULT FALSE NOT NULL, -- One primary category per item
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    PRIMARY KEY (content_id, category_id)
);

-- Content engagement tracking
CREATE TABLE content.engagement (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE CASCADE NOT NULL,
    content_id UUID REFERENCES content.items(id) ON DELETE CASCADE NOT NULL,
    
    -- Engagement details
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    completion_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    -- Interaction tracking
    pause_count INTEGER DEFAULT 0,
    skip_count INTEGER DEFAULT 0,
    replay_count INTEGER DEFAULT 0,
    interaction_events JSONB DEFAULT '[]' NOT NULL, -- Detailed interaction log
    
    -- Quality metrics
    enjoyed_rating INTEGER CONSTRAINT valid_enjoyed_rating CHECK (enjoyed_rating >= 1 AND enjoyed_rating <= 5),
    
    -- Session context
    session_id UUID, -- Links to broader activity session
    device_type VARCHAR(50),
    location_context VARCHAR(100), -- home, car, etc.
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT valid_completion_percentage CHECK (completion_percentage >= 0 AND completion_percentage <= 100),
    CONSTRAINT engagement_duration_logical CHECK (ended_at IS NULL OR ended_at >= started_at)
) PARTITION BY RANGE (created_at);

-- Create partitions for content engagement (monthly partitions)
CREATE TABLE content.engagement_2024_01 PARTITION OF content.engagement
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE content.engagement_2024_02 PARTITION OF content.engagement
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');
CREATE TABLE content.engagement_2024_03 PARTITION OF content.engagement
    FOR VALUES FROM ('2024-03-01') TO ('2024-04-01');

-- =============================================================================
-- AUDIO SCHEMA TABLES - Speech Analysis & Metrics
-- =============================================================================

-- Audio recording sessions (metadata only, no actual audio)
CREATE TABLE audio.sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Session timing
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_seconds INTEGER,
    
    -- Processing status
    status audio.session_status DEFAULT 'recording' NOT NULL,
    processing_started_at TIMESTAMP WITH TIME ZONE,
    processing_completed_at TIMESTAMP WITH TIME ZONE,
    processing_error TEXT,
    
    -- Session context
    location VARCHAR(100), -- home, car, playground
    background_noise_level VARCHAR(20), -- quiet, moderate, noisy
    device_id VARCHAR(255),
    app_version VARCHAR(50),
    
    -- Quality indicators
    audio_quality_score DECIMAL(3,2), -- 0-1 quality rating
    valid_speech_percentage DECIMAL(5,2), -- % of session with valid speech
    
    -- Privacy compliance
    consent_confirmed BOOLEAN DEFAULT TRUE NOT NULL,
    parent_present BOOLEAN DEFAULT TRUE NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT valid_session_duration CHECK (ended_at IS NULL OR ended_at >= started_at)
) PARTITION BY RANGE (started_at);

-- Create partitions for audio sessions (quarterly partitions)
CREATE TABLE audio.sessions_2024_q1 PARTITION OF audio.sessions
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE audio.sessions_2024_q2 PARTITION OF audio.sessions
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

-- Speech analysis metrics (aggregated from on-device processing)
CREATE TABLE audio.speech_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES audio.sessions(id) ON DELETE CASCADE NOT NULL,
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Time segment (metrics calculated for 5-minute segments)
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    
    -- Word and speech metrics (privacy-safe aggregations)
    word_count INTEGER DEFAULT 0 NOT NULL,
    unique_word_count INTEGER DEFAULT 0 NOT NULL,
    average_word_length DECIMAL(4,2) DEFAULT 0.0,
    longest_utterance_words INTEGER DEFAULT 0,
    
    -- Conversation dynamics
    conversation_turns INTEGER DEFAULT 0 NOT NULL,
    child_initiated_turns INTEGER DEFAULT 0 NOT NULL,
    adult_initiated_turns INTEGER DEFAULT 0 NOT NULL,
    average_response_time_ms INTEGER,
    
    -- Speech quality indicators  
    clarity_score DECIMAL(3,2), -- 0-1 speech clarity
    confidence_score DECIMAL(3,2), -- ML model confidence in analysis
    background_speech_detected BOOLEAN DEFAULT FALSE,
    overlapping_speech_percentage DECIMAL(5,2) DEFAULT 0.0,
    
    -- Emotional and engagement indicators
    positive_affect_detected BOOLEAN,
    engagement_level VARCHAR(20), -- low, medium, high
    excitement_indicators INTEGER DEFAULT 0, -- laughing, exclamations
    
    -- NO PERSONALLY IDENTIFIABLE INFORMATION STORED
    -- NO ACTUAL WORDS OR CONTENT STORED
    -- ONLY STATISTICAL AGGREGATIONS
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT valid_time_segment CHECK (end_time > start_time),
    CONSTRAINT valid_word_counts CHECK (unique_word_count <= word_count)
) PARTITION BY RANGE (start_time);

-- Create partitions for speech metrics (monthly partitions)
CREATE TABLE audio.speech_metrics_2024_01 PARTITION OF audio.speech_metrics
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE audio.speech_metrics_2024_02 PARTITION OF audio.speech_metrics
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- =============================================================================
-- ANALYTICS SCHEMA TABLES - Insights & Reporting
-- =============================================================================

-- Daily aggregated metrics per child
CREATE TABLE analytics.daily_child_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL,
    
    -- Speech and language metrics
    total_words INTEGER DEFAULT 0 NOT NULL,
    unique_words INTEGER DEFAULT 0 NOT NULL,
    conversation_turns INTEGER DEFAULT 0 NOT NULL,
    audio_session_count INTEGER DEFAULT 0 NOT NULL,
    total_audio_duration_minutes INTEGER DEFAULT 0 NOT NULL,
    
    -- Content engagement metrics
    content_sessions INTEGER DEFAULT 0 NOT NULL,
    total_screen_time_minutes INTEGER DEFAULT 0 NOT NULL,
    educational_content_minutes INTEGER DEFAULT 0 NOT NULL,
    completed_content_count INTEGER DEFAULT 0 NOT NULL,
    
    -- Development indicators
    vocabulary_diversity_score DECIMAL(4,2),
    engagement_score DECIMAL(3,2),
    milestone_achievements INTEGER DEFAULT 0 NOT NULL,
    
    -- Behavioral patterns
    most_active_hour INTEGER, -- 0-23
    preferred_content_types TEXT[] DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    UNIQUE(child_id, date)
) PARTITION BY RANGE (date);

-- Create partitions for daily metrics (quarterly partitions)
CREATE TABLE analytics.daily_child_metrics_2024_q1 PARTITION OF analytics.daily_child_metrics
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE analytics.daily_child_metrics_2024_q2 PARTITION OF analytics.daily_child_metrics
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

-- Development milestones tracking
CREATE TABLE analytics.milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE CASCADE NOT NULL,
    
    milestone_type VARCHAR(100) NOT NULL, -- language, motor, social, cognitive
    milestone_name VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Age expectations
    typical_age_months_min INTEGER NOT NULL,
    typical_age_months_max INTEGER NOT NULL,
    
    -- Achievement tracking
    achieved BOOLEAN DEFAULT FALSE NOT NULL,
    achieved_at TIMESTAMP WITH TIME ZONE,
    child_age_months_at_achievement INTEGER,
    
    -- Evidence and notes
    evidence_source VARCHAR(100), -- app_data, parent_report, professional_assessment
    confidence_level DECIMAL(3,2) DEFAULT 0.0, -- 0-1 confidence in achievement
    parent_notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    CONSTRAINT valid_age_range CHECK (typical_age_months_max >= typical_age_months_min)
);

-- Usage analytics and events
CREATE TABLE analytics.events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE,
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE CASCADE,
    session_id UUID,
    
    -- Event details
    event_type analytics.event_type NOT NULL,
    event_name VARCHAR(100) NOT NULL,
    event_properties JSONB DEFAULT '{}' NOT NULL,
    
    -- Context
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    device_info JSONB DEFAULT '{}' NOT NULL,
    app_version VARCHAR(50),
    
    -- Privacy-safe location data
    country VARCHAR(2), -- ISO country code only
    timezone VARCHAR(50),
    
    CONSTRAINT events_require_user_or_child CHECK (user_id IS NOT NULL OR child_id IS NOT NULL)
) PARTITION BY RANGE (timestamp);

-- Create partitions for events (monthly partitions)
CREATE TABLE analytics.events_2024_01 PARTITION OF analytics.events
    FOR VALUES FROM ('2024-01-01') TO ('2024-02-01');
CREATE TABLE analytics.events_2024_02 PARTITION OF analytics.events
    FOR VALUES FROM ('2024-02-01') TO ('2024-03-01');

-- =============================================================================
-- ML SCHEMA TABLES - Machine Learning & Recommendations
-- =============================================================================

-- Content recommendation models
CREATE TABLE ml.recommendation_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    model_type VARCHAR(50) NOT NULL, -- collaborative_filtering, content_based, hybrid
    version VARCHAR(20) NOT NULL,
    
    -- Model configuration
    parameters JSONB NOT NULL DEFAULT '{}',
    feature_importance JSONB DEFAULT '{}',
    performance_metrics JSONB DEFAULT '{}',
    
    -- Model lifecycle
    trained_at TIMESTAMP WITH TIME ZONE NOT NULL,
    deployed_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT FALSE NOT NULL,
    
    -- Training data info
    training_data_from TIMESTAMP WITH TIME ZONE NOT NULL,
    training_data_to TIMESTAMP WITH TIME ZONE NOT NULL,
    training_samples_count INTEGER NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Content recommendations for children
CREATE TABLE ml.content_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE CASCADE NOT NULL,
    content_id UUID REFERENCES content.items(id) ON DELETE CASCADE NOT NULL,
    model_id UUID REFERENCES ml.recommendation_models(id) ON DELETE SET NULL,
    
    -- Recommendation score and reasoning
    score DECIMAL(4,3) NOT NULL CONSTRAINT valid_rec_score CHECK (score >= 0 AND score <= 1),
    reasoning JSONB DEFAULT '{}' NOT NULL, -- Why this was recommended
    recommendation_type VARCHAR(50) NOT NULL, -- trending, similar_to_liked, age_appropriate
    
    -- Recommendation lifecycle
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    shown_to_user BOOLEAN DEFAULT FALSE NOT NULL,
    shown_at TIMESTAMP WITH TIME ZONE,
    
    -- User feedback
    user_action VARCHAR(50), -- viewed, liked, disliked, skipped, shared
    user_action_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(child_id, content_id, model_id, generated_at) -- Prevent duplicate recommendations
);

-- =============================================================================
-- SAFETY SCHEMA TABLES - Content Safety & Parental Controls
-- =============================================================================

-- Content safety reviews
CREATE TABLE safety.content_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_id UUID REFERENCES content.items(id) ON DELETE CASCADE NOT NULL,
    reviewed_by UUID REFERENCES core.users(id) ON DELETE SET NULL,
    
    -- Review details
    safety_rating safety.safety_rating NOT NULL,
    age_appropriate BOOLEAN NOT NULL,
    educational_value BOOLEAN NOT NULL,
    
    -- Specific safety checks
    contains_advertising BOOLEAN DEFAULT FALSE NOT NULL,
    contains_inappropriate_language BOOLEAN DEFAULT FALSE NOT NULL,
    contains_violence BOOLEAN DEFAULT FALSE NOT NULL,
    contains_scary_content BOOLEAN DEFAULT FALSE NOT NULL,
    data_collection_concerns BOOLEAN DEFAULT FALSE NOT NULL,
    
    -- Review notes and actions
    reviewer_notes TEXT,
    action_taken VARCHAR(100), -- approved, rejected, flagged_for_modification
    
    reviewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    -- Review confidence and source
    confidence_level DECIMAL(3,2) DEFAULT 1.0 NOT NULL, -- Human=1.0, AI varies
    review_source VARCHAR(50) DEFAULT 'human' NOT NULL -- human, ai, automated
);

-- Parental control settings per child
CREATE TABLE safety.parental_controls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE CASCADE NOT NULL,
    
    -- Time controls
    max_daily_screen_time_minutes INTEGER DEFAULT 60,
    allowed_time_ranges JSONB DEFAULT '[]' NOT NULL, -- Array of time ranges
    bedtime_restriction_enabled BOOLEAN DEFAULT TRUE NOT NULL,
    quiet_hours_start TIME,
    quiet_hours_end TIME,
    
    -- Content controls
    blocked_categories UUID[] DEFAULT '{}', -- Array of category IDs
    blocked_content UUID[] DEFAULT '{}', -- Array of content IDs
    allowed_content_only BOOLEAN DEFAULT FALSE NOT NULL, -- Whitelist mode
    require_parent_approval BOOLEAN DEFAULT FALSE NOT NULL,
    
    -- Safety settings
    max_age_rating_months INTEGER, -- Override default age matching
    educational_content_only BOOLEAN DEFAULT FALSE NOT NULL,
    block_user_generated_content BOOLEAN DEFAULT TRUE NOT NULL,
    
    -- Audio monitoring controls
    audio_monitoring_enabled BOOLEAN DEFAULT TRUE NOT NULL,
    share_data_with_professionals BOOLEAN DEFAULT FALSE NOT NULL,
    include_in_research BOOLEAN DEFAULT FALSE NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    
    UNIQUE(child_id) -- One control setting per child
);

-- =============================================================================
-- AUDIT SCHEMA TABLES - Audit Logs & Compliance
-- =============================================================================

-- Comprehensive audit log for compliance and security
CREATE TABLE audit.activity_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Who performed the action
    user_id UUID REFERENCES core.users(id) ON DELETE SET NULL,
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE SET NULL, -- If action relates to child
    
    -- What action was performed
    action audit.action_type NOT NULL,
    table_name VARCHAR(100) NOT NULL,
    record_id UUID,
    
    -- Action details
    old_values JSONB, -- Previous state (for updates/deletes)
    new_values JSONB, -- New state (for creates/updates)
    
    -- Context
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip_address INET,
    user_agent TEXT,
    session_id UUID,
    
    -- Additional metadata
    metadata JSONB DEFAULT '{}' NOT NULL,
    
    -- Compliance fields
    retention_until TIMESTAMP WITH TIME ZONE, -- When this can be deleted
    legal_hold BOOLEAN DEFAULT FALSE NOT NULL -- Legal hold prevents deletion
    
) PARTITION BY RANGE (timestamp);

-- Create partitions for audit log (quarterly partitions)
CREATE TABLE audit.activity_log_2024_q1 PARTITION OF audit.activity_log
    FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');
CREATE TABLE audit.activity_log_2024_q2 PARTITION OF audit.activity_log
    FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

-- Data retention policies
CREATE TABLE audit.data_retention_policies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(100) UNIQUE NOT NULL,
    retention_period_days INTEGER NOT NULL,
    retention_criteria JSONB DEFAULT '{}' NOT NULL,
    
    -- Policy details
    description TEXT NOT NULL,
    legal_basis TEXT, -- COPPA, GDPR, business requirement
    
    -- Policy status
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- =============================================================================
-- CREATE TRIGGERS FOR UPDATED_AT TIMESTAMPS
-- =============================================================================

-- Add updated_at triggers for all tables that need them
CREATE TRIGGER users_updated_at BEFORE UPDATE ON core.users
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

CREATE TRIGGER families_updated_at BEFORE UPDATE ON family.families
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

CREATE TRIGGER child_profiles_updated_at BEFORE UPDATE ON family.child_profiles
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

CREATE TRIGGER plans_updated_at BEFORE UPDATE ON subscription.plans
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

CREATE TRIGGER user_subscriptions_updated_at BEFORE UPDATE ON subscription.user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

CREATE TRIGGER categories_updated_at BEFORE UPDATE ON content.categories
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

CREATE TRIGGER creators_updated_at BEFORE UPDATE ON content.creators
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

CREATE TRIGGER items_updated_at BEFORE UPDATE ON content.items
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

CREATE TRIGGER milestones_updated_at BEFORE UPDATE ON analytics.milestones
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

CREATE TRIGGER parental_controls_updated_at BEFORE UPDATE ON safety.parental_controls
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

CREATE TRIGGER data_retention_policies_updated_at BEFORE UPDATE ON audit.data_retention_policies
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

-- =============================================================================
-- COMMENTS
-- =============================================================================

-- Add table comments for documentation
COMMENT ON TABLE core.users IS 'Parent user accounts with authentication and profile information';
COMMENT ON TABLE core.user_sessions IS 'Active login sessions with device and location tracking';
COMMENT ON TABLE family.families IS 'Family groups containing parents and children';
COMMENT ON TABLE family.child_profiles IS 'Child profiles with minimal data for COPPA compliance';
COMMENT ON TABLE content.items IS 'Curated content library with safety ratings and metadata';
COMMENT ON TABLE audio.sessions IS 'Audio recording session metadata (no raw audio stored)';
COMMENT ON TABLE audio.speech_metrics IS 'Aggregated speech analysis results from on-device processing';
COMMENT ON TABLE analytics.daily_child_metrics IS 'Daily aggregated development and engagement metrics';
COMMENT ON TABLE audit.activity_log IS 'Comprehensive audit trail for compliance and security';

SELECT 'All tables created successfully with constraints, partitioning, and triggers.' AS result;