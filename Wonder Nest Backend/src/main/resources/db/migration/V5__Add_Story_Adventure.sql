-- V5__Add_Story_Adventure.sql
-- Add Story Adventure feature tables to games schema
-- This migration adds comprehensive support for interactive storytelling with vocabulary learning

SET search_path TO games, public;

-- =============================================================================
-- STORY ADVENTURE CORE TABLES
-- =============================================================================

-- Story templates master table - stores reusable story structures
CREATE TABLE IF NOT EXISTS story_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    creator_id UUID, -- References core.users(id) - nullable for system templates
    
    -- Age and difficulty targeting
    age_group VARCHAR(10) CHECK (age_group IN ('3-5', '6-8', '9-12')) NOT NULL,
    difficulty VARCHAR(20) CHECK (difficulty IN ('emerging', 'developing', 'fluent')) NOT NULL,
    
    -- Story content (flexible JSON structure)
    content JSONB NOT NULL DEFAULT '{}',
    vocabulary_words TEXT[] DEFAULT '{}',
    
    -- Template metadata
    page_count INTEGER DEFAULT 0,
    estimated_read_time INTEGER DEFAULT 0, -- in minutes
    language VARCHAR(5) DEFAULT 'en',
    version VARCHAR(10) DEFAULT '1.0.0',
    
    -- Availability and monetization
    is_premium BOOLEAN DEFAULT false,
    is_marketplace BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    is_private BOOLEAN DEFAULT false, -- Private templates only visible to creator
    
    -- Educational metadata
    educational_goals TEXT[] DEFAULT '{}',
    themes TEXT[] DEFAULT '{}',
    tags TEXT[] DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Story instances - tracks each child's reading sessions
CREATE TABLE IF NOT EXISTS story_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL, -- References core.children(id)
    template_id UUID NOT NULL REFERENCES story_templates(id) ON DELETE CASCADE,
    
    -- Reading progress
    status VARCHAR(20) CHECK (status IN ('in_progress', 'completed', 'abandoned')) DEFAULT 'in_progress',
    current_page INTEGER DEFAULT 1,
    total_pages INTEGER DEFAULT 0,
    
    -- Customizations and settings
    customizations JSONB DEFAULT '{}', -- Character names, variable substitutions
    reading_mode VARCHAR(20) DEFAULT 'self_paced', -- 'self_paced', 'guided', 'audio_only'
    audio_enabled BOOLEAN DEFAULT true,
    
    -- Progress tracking
    progress_data JSONB DEFAULT '{}', -- Detailed page-by-page progress
    vocabulary_interactions JSONB DEFAULT '{}', -- Words tapped, definitions viewed
    comprehension_answers JSONB DEFAULT '{}', -- Quiz responses
    
    -- Session timing
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    total_reading_time INTEGER DEFAULT 0, -- in seconds
    
    -- Performance metrics
    reading_speed_wpm INTEGER DEFAULT 0,
    comprehension_score INTEGER DEFAULT 0,
    vocabulary_score INTEGER DEFAULT 0,
    
    UNIQUE(child_id, template_id, started_at) -- Allow multiple attempts but track by start time
);

-- Vocabulary progress tracking - per child vocabulary development
CREATE TABLE IF NOT EXISTS vocabulary_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL, -- References core.children(id)
    word VARCHAR(100) NOT NULL,
    
    -- Learning metrics
    encounters INTEGER DEFAULT 1,
    correct_uses INTEGER DEFAULT 0,
    incorrect_uses INTEGER DEFAULT 0,
    mastery_level INTEGER DEFAULT 0 CHECK (mastery_level >= 0 AND mastery_level <= 100),
    
    -- Context tracking
    last_seen_in UUID REFERENCES story_templates(id),
    definition_viewed_count INTEGER DEFAULT 0,
    pronunciation_played_count INTEGER DEFAULT 0,
    
    -- Timing
    first_encountered TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_encountered TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    mastered_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(child_id, word)
);

-- Marketplace listings - stories available for purchase
CREATE TABLE IF NOT EXISTS marketplace_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES story_templates(id) ON DELETE CASCADE UNIQUE,
    seller_id UUID NOT NULL, -- References core.users(id)
    
    -- Pricing
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    original_price DECIMAL(10, 2),
    currency VARCHAR(3) DEFAULT 'USD',
    
    -- Marketplace status
    status VARCHAR(20) CHECK (status IN ('pending', 'approved', 'rejected', 'suspended', 'inactive')) DEFAULT 'pending',
    moderation_notes TEXT,
    
    -- Performance metrics
    rating DECIMAL(2, 1) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5.0),
    review_count INTEGER DEFAULT 0,
    purchase_count INTEGER DEFAULT 0,
    revenue_total DECIMAL(10, 2) DEFAULT 0.00,
    
    -- Listing metadata
    marketing_title VARCHAR(255), -- Different from template title for marketing
    marketing_description TEXT,
    featured_image_url TEXT,
    preview_pages INTEGER[] DEFAULT '{}',
    
    -- SEO and discovery
    search_keywords TEXT[] DEFAULT '{}',
    category_tags TEXT[] DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    approved_at TIMESTAMP WITH TIME ZONE,
    featured_until TIMESTAMP WITH TIME ZONE
);

-- Purchase history - tracks all story purchases
CREATE TABLE IF NOT EXISTS story_purchases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    buyer_id UUID NOT NULL, -- References core.users(id)
    listing_id UUID NOT NULL REFERENCES marketplace_listings(id),
    child_id UUID, -- References core.children(id) - nullable if family purchase
    
    -- Transaction details
    price_paid DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    transaction_id VARCHAR(255) UNIQUE, -- External payment system reference
    payment_method VARCHAR(50),
    
    -- Purchase metadata
    purchased_for_child_ids UUID[], -- If purchasing for specific children
    gift_message TEXT,
    purchase_notes JSONB DEFAULT '{}',
    
    purchased_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Story analytics - detailed event tracking for learning insights
CREATE TABLE IF NOT EXISTS story_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL, -- References core.children(id)
    instance_id UUID REFERENCES story_instances(id),
    template_id UUID REFERENCES story_templates(id),
    
    -- Event classification
    event_type VARCHAR(50) NOT NULL, -- 'page_turn', 'word_tap', 'quiz_answer', 'session_start', etc.
    event_category VARCHAR(50), -- 'reading', 'vocabulary', 'comprehension', 'navigation'
    
    -- Event data
    event_data JSONB NOT NULL DEFAULT '{}',
    page_number INTEGER,
    session_id UUID, -- Group events by reading session
    
    -- Context
    device_type VARCHAR(50),
    app_version VARCHAR(20),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Marketplace reviews - user feedback on purchased stories
CREATE TABLE IF NOT EXISTS marketplace_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID NOT NULL REFERENCES marketplace_listings(id) ON DELETE CASCADE,
    reviewer_id UUID NOT NULL, -- References core.users(id)
    purchase_id UUID REFERENCES story_purchases(id),
    
    -- Review content
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    title VARCHAR(200),
    review_text TEXT,
    
    -- Review metadata
    is_verified_purchase BOOLEAN DEFAULT false,
    child_age_when_reviewed INTEGER, -- Age in months
    helpful_votes INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(listing_id, reviewer_id) -- One review per user per listing
);

-- =============================================================================
-- PERFORMANCE INDEXES
-- =============================================================================

-- Story templates indexes
CREATE INDEX IF NOT EXISTS idx_story_templates_creator ON story_templates(creator_id);
CREATE INDEX IF NOT EXISTS idx_story_templates_age_difficulty ON story_templates(age_group, difficulty);
CREATE INDEX IF NOT EXISTS idx_story_templates_marketplace ON story_templates(is_marketplace, is_active);
CREATE INDEX IF NOT EXISTS idx_story_templates_tags ON story_templates USING GIN(tags);
CREATE INDEX IF NOT EXISTS idx_story_templates_vocabulary ON story_templates USING GIN(vocabulary_words);

-- Story instances indexes
CREATE INDEX IF NOT EXISTS idx_story_instances_child ON story_instances(child_id, status);
CREATE INDEX IF NOT EXISTS idx_story_instances_template ON story_instances(template_id);
CREATE INDEX IF NOT EXISTS idx_story_instances_last_accessed ON story_instances(last_accessed_at DESC);
CREATE INDEX IF NOT EXISTS idx_story_instances_progress ON story_instances(child_id, status, last_accessed_at);

-- Vocabulary progress indexes
CREATE INDEX IF NOT EXISTS idx_vocabulary_child_word ON vocabulary_progress(child_id, word);
CREATE INDEX IF NOT EXISTS idx_vocabulary_mastery ON vocabulary_progress(child_id, mastery_level DESC);
CREATE INDEX IF NOT EXISTS idx_vocabulary_last_encountered ON vocabulary_progress(last_encountered DESC);

-- Marketplace indexes
CREATE INDEX IF NOT EXISTS idx_marketplace_status_rating ON marketplace_listings(status, rating DESC);
CREATE INDEX IF NOT EXISTS idx_marketplace_seller ON marketplace_listings(seller_id);
CREATE INDEX IF NOT EXISTS idx_marketplace_categories ON marketplace_listings USING GIN(category_tags);
CREATE INDEX IF NOT EXISTS idx_marketplace_keywords ON marketplace_listings USING GIN(search_keywords);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_story_analytics_child_date ON story_analytics(child_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_story_analytics_event_type ON story_analytics(event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_story_analytics_session ON story_analytics(session_id);
CREATE INDEX IF NOT EXISTS idx_story_analytics_template ON story_analytics(template_id, created_at DESC);

-- Purchase history indexes
CREATE INDEX IF NOT EXISTS idx_story_purchases_buyer ON story_purchases(buyer_id, purchased_at DESC);
CREATE INDEX IF NOT EXISTS idx_story_purchases_listing ON story_purchases(listing_id);
CREATE INDEX IF NOT EXISTS idx_story_purchases_child ON story_purchases(child_id) WHERE child_id IS NOT NULL;

-- Reviews indexes
CREATE INDEX IF NOT EXISTS idx_marketplace_reviews_listing ON marketplace_reviews(listing_id, rating DESC);
CREATE INDEX IF NOT EXISTS idx_marketplace_reviews_reviewer ON marketplace_reviews(reviewer_id);

-- =============================================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =============================================================================

-- Auto-update timestamps for story_templates
DROP TRIGGER IF EXISTS update_story_templates_updated_at ON story_templates;
CREATE TRIGGER update_story_templates_updated_at
    BEFORE UPDATE ON story_templates
    FOR EACH ROW
    EXECUTE FUNCTION games.update_updated_at();

-- Auto-update timestamps for marketplace_listings
DROP TRIGGER IF EXISTS update_marketplace_listings_updated_at ON marketplace_listings;
CREATE TRIGGER update_marketplace_listings_updated_at
    BEFORE UPDATE ON marketplace_listings
    FOR EACH ROW
    EXECUTE FUNCTION games.update_updated_at();

-- Auto-update timestamps for marketplace_reviews
DROP TRIGGER IF EXISTS update_marketplace_reviews_updated_at ON marketplace_reviews;
CREATE TRIGGER update_marketplace_reviews_updated_at
    BEFORE UPDATE ON marketplace_reviews
    FOR EACH ROW
    EXECUTE FUNCTION games.update_updated_at();

-- Auto-update last_accessed_at for story_instances when progress is updated
CREATE OR REPLACE FUNCTION games.update_story_instance_access()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_accessed_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_story_instances_access ON story_instances;
CREATE TRIGGER update_story_instances_access
    BEFORE UPDATE ON story_instances
    FOR EACH ROW
    EXECUTE FUNCTION games.update_story_instance_access();

-- =============================================================================
-- INITIAL SEED DATA
-- =============================================================================

-- Insert some system story templates for initial content
INSERT INTO story_templates (
    title, description, age_group, difficulty, content, vocabulary_words, 
    page_count, estimated_read_time, educational_goals, themes, tags, is_private
) VALUES 
(
    'Welcome to Story Adventure',
    'Your very first interactive story adventure! Meet friendly characters and learn new words.',
    '3-5',
    'emerging',
    '{"pages": [{"text": "Welcome to Story Adventure!", "imageUrl": "welcome.jpg", "vocabularyWords": [{"word": "adventure", "definition": "An exciting journey or experience"}]}]}',
    ARRAY['adventure', 'welcome', 'story'],
    5,
    3,
    ARRAY['vocabulary', 'reading engagement'],
    ARRAY['welcome', 'introduction'],
    ARRAY['beginner', 'introduction', 'system'],
    false
),
(
    'The Magic Garden',
    'Explore a magical garden filled with talking flowers and friendly bugs.',
    '3-5',
    'emerging',
    '{"pages": [{"text": "In a {adjective} garden far away...", "imageUrl": "garden.jpg", "vocabularyWords": [{"word": "garden", "definition": "A place where plants and flowers grow"}]}]}',
    ARRAY['garden', 'flower', 'butterfly', 'grow'],
    8,
    5,
    ARRAY['vocabulary', 'nature awareness'],
    ARRAY['nature', 'magic', 'exploration'],
    ARRAY['nature', 'magic', 'beginner'],
    false
),
(
    'Ocean Adventure',
    'Dive deep into the ocean and meet amazing sea creatures.',
    '6-8',
    'developing',
    '{"pages": [{"text": "Deep in the blue ocean...", "imageUrl": "ocean.jpg", "vocabularyWords": [{"word": "ocean", "definition": "A very large body of salt water"}]}]}',
    ARRAY['ocean', 'fish', 'coral', 'deep', 'swim'],
    12,
    8,
    ARRAY['vocabulary', 'marine biology', 'reading comprehension'],
    ARRAY['ocean', 'animals', 'science'],
    ARRAY['science', 'ocean', 'adventure'],
    false
);

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant permissions to application users
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA games TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA games TO wondernest_app;

-- Grant read permissions to analytics user
GRANT SELECT ON ALL TABLES IN SCHEMA games TO wondernest_analytics;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE games.story_templates IS 'Story templates - reusable story structures with placeholders for customization';
COMMENT ON TABLE games.story_instances IS 'Story instances - tracks individual child reading sessions and progress';
COMMENT ON TABLE games.vocabulary_progress IS 'Vocabulary progress - tracks word learning and mastery per child';
COMMENT ON TABLE games.marketplace_listings IS 'Marketplace listings - stories available for purchase';
COMMENT ON TABLE games.story_purchases IS 'Purchase history - tracks all story marketplace transactions';
COMMENT ON TABLE games.story_analytics IS 'Story analytics - detailed event tracking for learning insights';
COMMENT ON TABLE games.marketplace_reviews IS 'Marketplace reviews - user feedback on purchased stories';

-- Update database version
INSERT INTO core.database_info (key, value) VALUES ('story_adventure_version', '1.0.0')
ON CONFLICT (key) DO UPDATE SET value = '1.0.0';