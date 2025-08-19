-- =============================================================================
-- V3: GAMES SCHEMA - Mini-Game System
-- =============================================================================
-- This migration creates the complete games infrastructure following the
-- plugin-based architecture design for WonderNest mini-games.

-- Create games schema
CREATE SCHEMA IF NOT EXISTS games;
COMMENT ON SCHEMA games IS 'Mini-games system with plugin architecture for educational games';

-- =============================================================================
-- ENUM TYPES
-- =============================================================================

-- Implementation types for games
CREATE TYPE games.implementation_type AS ENUM (
    'native',     -- Flutter native implementation
    'web',        -- WebView-based game
    'hybrid'      -- Mixed native/web implementation
);

-- Achievement rarity levels
CREATE TYPE games.achievement_rarity AS ENUM (
    'common',
    'uncommon', 
    'rare',
    'epic',
    'legendary'
);

-- =============================================================================
-- CORE GAME TABLES
-- =============================================================================

-- Game types (categories of games)
CREATE TABLE games.game_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    default_schema JSONB NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE games.game_types IS 'Categories of games (collection, puzzle, creative, educational)';
COMMENT ON COLUMN games.game_types.default_schema IS 'Default data structure for games of this type';

-- Game categories for organization
CREATE TABLE games.game_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) UNIQUE NOT NULL,
    parent_category_id UUID REFERENCES games.game_categories(id),
    icon_url VARCHAR(500),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE games.game_categories IS 'Hierarchical categories for game organization';

-- Main game registry - all available games
CREATE TABLE games.game_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_key VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    description TEXT,
    version VARCHAR(20) NOT NULL DEFAULT '1.0.0',
    
    -- Game metadata
    game_type_id UUID REFERENCES games.game_types(id) NOT NULL,
    category_id UUID REFERENCES games.game_categories(id),
    
    -- Age targeting
    min_age_months INTEGER NOT NULL DEFAULT 24,
    max_age_months INTEGER NOT NULL DEFAULT 144,
    
    -- Configuration
    configuration JSONB NOT NULL DEFAULT '{}',
    default_settings JSONB NOT NULL DEFAULT '{}',
    
    -- Implementation
    implementation_type games.implementation_type NOT NULL DEFAULT 'native',
    entry_point VARCHAR(500),
    resource_bundle_url VARCHAR(500),
    
    -- Content safety
    content_rating VARCHAR(20) DEFAULT 'everyone',
    safety_reviewed BOOLEAN DEFAULT FALSE,
    safety_reviewed_at TIMESTAMP WITH TIME ZONE,
    safety_reviewer_id UUID REFERENCES core.users(id),
    
    -- Availability
    is_active BOOLEAN DEFAULT FALSE,
    is_premium BOOLEAN DEFAULT FALSE,
    release_date TIMESTAMP WITH TIME ZONE,
    sunset_date TIMESTAMP WITH TIME ZONE,
    
    -- Metadata
    tags JSONB DEFAULT '[]',
    keywords JSONB DEFAULT '[]',
    educational_objectives JSONB DEFAULT '[]',
    skills_developed JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_age_range CHECK (max_age_months >= min_age_months)
);

COMMENT ON TABLE games.game_registry IS 'Registry of all available games with plugin configuration';

-- =============================================================================
-- CHILD GAME INSTANCES
-- =============================================================================

-- Child-specific game instances
CREATE TABLE games.child_game_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE CASCADE,
    game_id UUID REFERENCES games.game_registry(id) ON DELETE CASCADE,
    
    -- Instance configuration
    settings JSONB NOT NULL DEFAULT '{}',
    preferences JSONB NOT NULL DEFAULT '{}',
    
    -- Progress tracking
    is_unlocked BOOLEAN DEFAULT TRUE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    first_played_at TIMESTAMP WITH TIME ZONE,
    last_played_at TIMESTAMP WITH TIME ZONE,
    
    -- Statistics
    total_play_time_minutes INTEGER DEFAULT 0,
    session_count INTEGER DEFAULT 0,
    
    -- Status
    is_favorite BOOLEAN DEFAULT FALSE,
    is_completed BOOLEAN DEFAULT FALSE,
    completion_percentage DECIMAL(5,2) DEFAULT 0.00,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(child_id, game_id),
    CONSTRAINT valid_completion CHECK (completion_percentage >= 0 AND completion_percentage <= 100)
);

COMMENT ON TABLE games.child_game_instances IS 'Per-child game instances with settings and progress';

-- Flexible game data storage
CREATE TABLE games.child_game_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_game_instance_id UUID REFERENCES games.child_game_instances(id) ON DELETE CASCADE,
    data_key VARCHAR(200) NOT NULL,
    data_version INTEGER NOT NULL DEFAULT 1,
    data_value JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(child_game_instance_id, data_key)
);

COMMENT ON TABLE games.child_game_data IS 'Flexible key-value storage for game-specific data';
COMMENT ON COLUMN games.child_game_data.data_key IS 'Keys like: sticker_books, collections, inventory, etc.';

-- =============================================================================
-- GAME SESSIONS
-- =============================================================================

CREATE TABLE games.game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_game_instance_id UUID REFERENCES games.child_game_instances(id) ON DELETE CASCADE,
    
    -- Session timing
    started_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    
    -- Session context
    device_type VARCHAR(50),
    app_version VARCHAR(50),
    game_version VARCHAR(20),
    
    -- Metrics
    session_data JSONB DEFAULT '{}',
    events JSONB DEFAULT '[]',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_session_duration CHECK (
        (ended_at IS NULL) OR 
        (ended_at >= started_at)
    )
);

COMMENT ON TABLE games.game_sessions IS 'Individual game play sessions for analytics';

-- =============================================================================
-- ACHIEVEMENTS SYSTEM
-- =============================================================================

CREATE TABLE games.achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID REFERENCES games.game_registry(id) ON DELETE CASCADE,
    
    achievement_key VARCHAR(200) NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    icon_url VARCHAR(500),
    
    -- Unlock criteria
    criteria JSONB NOT NULL,
    points INTEGER DEFAULT 10,
    
    -- Display
    category VARCHAR(100),
    rarity games.achievement_rarity DEFAULT 'common',
    sort_order INTEGER DEFAULT 0,
    is_secret BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(game_id, achievement_key)
);

COMMENT ON TABLE games.achievements IS 'Achievement definitions per game';

CREATE TABLE games.child_achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_game_instance_id UUID REFERENCES games.child_game_instances(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES games.achievements(id) ON DELETE CASCADE,
    
    unlocked_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    game_session_id UUID REFERENCES games.game_sessions(id),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(child_game_instance_id, achievement_id)
);

COMMENT ON TABLE games.child_achievements IS 'Achievements unlocked by children';

-- =============================================================================
-- SHARED ASSET SYSTEM
-- =============================================================================

CREATE TABLE games.game_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_type VARCHAR(50) NOT NULL, -- 'sticker', 'background', 'sound', 'sprite'
    asset_category VARCHAR(100),
    name VARCHAR(200) NOT NULL,
    
    -- Asset data
    url VARCHAR(500),
    thumbnail_url VARCHAR(500),
    metadata JSONB DEFAULT '{}',
    
    -- Monetization
    is_premium BOOLEAN DEFAULT FALSE,
    wonder_coin_price INTEGER DEFAULT 0,
    
    -- Age targeting
    min_age_months INTEGER DEFAULT 0,
    max_age_months INTEGER DEFAULT 999,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE games.game_assets IS 'Reusable assets that can be shared across games';

-- Link assets to games (many-to-many)
CREATE TABLE games.game_asset_registry (
    game_id UUID REFERENCES games.game_registry(id) ON DELETE CASCADE,
    asset_id UUID REFERENCES games.game_assets(id) ON DELETE CASCADE,
    usage_context JSONB,
    is_starter BOOLEAN DEFAULT FALSE,
    unlock_requirement JSONB,
    
    PRIMARY KEY (game_id, asset_id)
);

COMMENT ON TABLE games.game_asset_registry IS 'Links assets to games with context';

-- =============================================================================
-- PARENT APPROVAL SYSTEM
-- =============================================================================

CREATE TABLE games.parent_approvals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE CASCADE,
    game_id UUID REFERENCES games.game_registry(id),
    
    -- Request details
    approval_type VARCHAR(100) NOT NULL, -- 'custom_content', 'premium_purchase', 'sharing'
    request_context VARCHAR(500),
    request_data JSONB NOT NULL,
    
    -- Approval status
    status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    parent_id UUID REFERENCES core.users(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,
    
    -- Auto-expiry
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (CURRENT_TIMESTAMP + INTERVAL '7 days'),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'rejected'))
);

COMMENT ON TABLE games.parent_approvals IS 'Generic approval system for parent consent';

-- =============================================================================
-- VIRTUAL CURRENCY
-- =============================================================================

CREATE TABLE games.virtual_currency (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID REFERENCES family.child_profiles(id) UNIQUE,
    balance INTEGER DEFAULT 0,
    total_earned INTEGER DEFAULT 0,
    total_spent INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT non_negative_balance CHECK (balance >= 0)
);

COMMENT ON TABLE games.virtual_currency IS 'Wonder Coins balance per child';

CREATE TABLE games.currency_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID REFERENCES family.child_profiles(id),
    amount INTEGER NOT NULL,
    transaction_type VARCHAR(50), -- 'earned', 'spent', 'bonus', 'refund'
    source VARCHAR(100), -- game_id, achievement_id, purchase_id
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_transaction_type CHECK (
        transaction_type IN ('earned', 'spent', 'bonus', 'refund')
    )
);

COMMENT ON TABLE games.currency_transactions IS 'Transaction history for virtual currency';

-- =============================================================================
-- ANALYTICS
-- =============================================================================

CREATE TABLE games.daily_game_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID REFERENCES family.child_profiles(id) ON DELETE CASCADE,
    game_id UUID REFERENCES games.game_registry(id),
    date DATE NOT NULL,
    
    -- Metrics
    play_time_minutes INTEGER DEFAULT 0,
    sessions_count INTEGER DEFAULT 0,
    achievements_unlocked INTEGER DEFAULT 0,
    metrics JSONB DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(child_id, game_id, date)
);

COMMENT ON TABLE games.daily_game_metrics IS 'Daily aggregated metrics per game per child';

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Game registry indexes
CREATE INDEX idx_game_registry_active ON games.game_registry(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_game_registry_type_category ON games.game_registry(game_type_id, category_id);
CREATE INDEX idx_game_registry_age_range ON games.game_registry(min_age_months, max_age_months);

-- Child game instances indexes
CREATE INDEX idx_child_game_instances_child ON games.child_game_instances(child_id);
CREATE INDEX idx_child_game_instances_game ON games.child_game_instances(game_id);
CREATE INDEX idx_child_game_instances_last_played ON games.child_game_instances(last_played_at);

-- Game data indexes
CREATE INDEX idx_child_game_data_instance ON games.child_game_data(child_game_instance_id);
CREATE INDEX idx_child_game_data_key ON games.child_game_data(data_key);

-- Session indexes
CREATE INDEX idx_game_sessions_instance ON games.game_sessions(child_game_instance_id);
CREATE INDEX idx_game_sessions_date ON games.game_sessions(started_at);

-- Achievement indexes
CREATE INDEX idx_achievements_game ON games.achievements(game_id);
CREATE INDEX idx_child_achievements_instance ON games.child_achievements(child_game_instance_id);

-- Approval indexes
CREATE INDEX idx_parent_approvals_child ON games.parent_approvals(child_id);
CREATE INDEX idx_parent_approvals_status ON games.parent_approvals(status) WHERE status = 'pending';

-- Analytics indexes
CREATE INDEX idx_daily_game_metrics_child_date ON games.daily_game_metrics(child_id, date);
CREATE INDEX idx_daily_game_metrics_game_date ON games.daily_game_metrics(game_id, date);

-- =============================================================================
-- FUNCTIONS AND TRIGGERS
-- =============================================================================

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION games.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply update trigger to relevant tables
CREATE TRIGGER update_game_registry_updated_at
    BEFORE UPDATE ON games.game_registry
    FOR EACH ROW
    EXECUTE FUNCTION games.update_updated_at();

CREATE TRIGGER update_child_game_instances_updated_at
    BEFORE UPDATE ON games.child_game_instances
    FOR EACH ROW
    EXECUTE FUNCTION games.update_updated_at();

CREATE TRIGGER update_child_game_data_updated_at
    BEFORE UPDATE ON games.child_game_data
    FOR EACH ROW
    EXECUTE FUNCTION games.update_updated_at();

-- =============================================================================
-- INITIAL DATA
-- =============================================================================

-- Insert basic game types
INSERT INTO games.game_types (name, description, default_schema) VALUES
('collection', 'Collection-based games where children gather items', 
 '{"collections": [], "inventory": {}, "display_settings": {}}'::JSONB),
('puzzle', 'Problem-solving and logic games',
 '{"current_level": 1, "solved_puzzles": [], "hints_used": 0}'::JSONB),
('creative', 'Creative expression games like drawing and building',
 '{"creations": [], "tools_unlocked": [], "gallery": []}'::JSONB),
('educational', 'Learning-focused games for various subjects',
 '{"lessons_completed": [], "score": 0, "knowledge_areas": {}}'::JSONB);

-- Insert basic categories
INSERT INTO games.game_categories (name, sort_order) VALUES
('Stickers', 10),
('Drawing', 20),
('Math', 30),
('Reading', 40),
('Science', 50),
('Music', 60);

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant appropriate permissions
GRANT USAGE ON SCHEMA games TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA games TO wondernest_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA games TO wondernest_app;

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON SCHEMA games IS 'Complete mini-game system with plugin architecture supporting educational games, achievements, virtual currency, and parental controls';