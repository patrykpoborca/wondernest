-- V3__Add_Games_Schema.sql
-- Add games schema and tables for game data storage
-- This migration adds the missing games schema that the backend code expects

-- =============================================================================
-- GAMES SCHEMA - Game Data Storage
-- =============================================================================
CREATE SCHEMA IF NOT EXISTS games;
SET search_path TO games, public;

-- Simple game data table (used by AnalyticsRoutes.kt)
-- This is the primary table for storing game data like sticker book projects
CREATE TABLE IF NOT EXISTS simple_game_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL, -- Direct UUID reference to family.child_profiles.id
    game_type VARCHAR(100) NOT NULL, -- e.g., 'sticker_book', 'drawing'
    data_key VARCHAR(200) NOT NULL, -- e.g., 'sticker_project_123'
    data_value JSONB NOT NULL DEFAULT '{}', -- Flexible JSON storage for game-specific data
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Ensure uniqueness per child+game_type+data_key combination
    UNIQUE(child_id, game_type, data_key)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_simple_game_data_child_id ON simple_game_data(child_id);
CREATE INDEX IF NOT EXISTS idx_simple_game_data_game_type ON simple_game_data(game_type);
CREATE INDEX IF NOT EXISTS idx_simple_game_data_updated_at ON simple_game_data(updated_at);

-- Full-text search index on JSON data for advanced queries
CREATE INDEX IF NOT EXISTS idx_simple_game_data_content ON simple_game_data USING gin(data_value);

-- Add function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION games.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add trigger to auto-update timestamps
DROP TRIGGER IF EXISTS update_simple_game_data_updated_at ON simple_game_data;
CREATE TRIGGER update_simple_game_data_updated_at
    BEFORE UPDATE ON simple_game_data
    FOR EACH ROW
    EXECUTE FUNCTION games.update_updated_at_column();

-- =============================================================================
-- ADDITIONAL GAME TABLES (for future expansion)
-- =============================================================================

-- Game sessions table for tracking play sessions
CREATE TABLE IF NOT EXISTS game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL,
    game_type VARCHAR(100) NOT NULL,
    session_id VARCHAR(200) NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    session_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_game_sessions_child_id ON game_sessions(child_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_game_type ON game_sessions(game_type);
CREATE INDEX IF NOT EXISTS idx_game_sessions_started_at ON game_sessions(started_at);

-- Virtual currency table for child rewards
CREATE TABLE IF NOT EXISTS virtual_currency (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL UNIQUE,
    balance INTEGER DEFAULT 0,
    total_earned INTEGER DEFAULT 0,
    total_spent INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_virtual_currency_child_id ON virtual_currency(child_id);

-- Currency transactions table
CREATE TABLE IF NOT EXISTS currency_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL,
    amount INTEGER NOT NULL,
    transaction_type VARCHAR(50) NOT NULL, -- 'earned', 'spent', 'bonus', 'refund'
    source_reference VARCHAR(100), -- game_id, achievement_id, etc.
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_currency_transactions_child_id ON currency_transactions(child_id);
CREATE INDEX IF NOT EXISTS idx_currency_transactions_type ON currency_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_currency_transactions_created_at ON currency_transactions(created_at);

-- =============================================================================
-- Grant permissions to application users
-- =============================================================================

-- Grant permissions to wondernest_app user
GRANT USAGE ON SCHEMA games TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA games TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA games TO wondernest_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA games TO wondernest_app;

-- Grant read-only permissions to wondernest_analytics user  
GRANT USAGE ON SCHEMA games TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA games TO wondernest_analytics;

-- Update version info
INSERT INTO core.database_info (key, value) VALUES ('schema_version', '3.0.0')
ON CONFLICT (key) DO UPDATE SET value = '3.0.0';

-- Add comment for future reference
COMMENT ON SCHEMA games IS 'Game data storage schema - contains game progress, saved projects, and virtual currency';
COMMENT ON TABLE games.simple_game_data IS 'Primary table for storing game data like sticker book projects, drawings, etc.';