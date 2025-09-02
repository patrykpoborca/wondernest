-- V26: Add Content Packs System
-- Migration for comprehensive content packs marketplace with rich media support

-- Content Pack Categories (Animals, Fantasy, Educational, etc.)
CREATE TABLE IF NOT EXISTS content_pack_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    display_order INTEGER DEFAULT 0,
    icon_url TEXT,
    color_hex VARCHAR(7), -- #RRGGBB format
    is_active BOOLEAN DEFAULT true,
    age_min INTEGER DEFAULT 3,
    age_max INTEGER DEFAULT 12,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Content Pack Types (Characters, Backgrounds, Stickers, Audio, etc.)
CREATE TYPE content_pack_type AS ENUM (
    'character_bundle',
    'backdrop_collection', 
    'sticker_pack',
    'sound_effects',
    'music_collection',
    'voice_pack',
    'emoji_pack',
    'sprite_sheet',
    'interactive_objects',
    'particle_effects',
    'texture_pack',
    'animation_bundle',
    'educational_theme'
);

-- Media Types for individual assets
CREATE TYPE media_type AS ENUM (
    'image_static',
    'image_animated',
    'sprite_sheet',
    'vector_animation',
    'audio_sound',
    'audio_music',
    'audio_voice',
    'video_short',
    'interactive_object',
    'particle_system',
    'texture_3d',
    'model_3d',
    'font_custom'
);

-- Content Packs (the main pack entity)
CREATE TABLE IF NOT EXISTS content_packs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    short_description VARCHAR(500),
    pack_type content_pack_type NOT NULL,
    category_id UUID REFERENCES content_pack_categories(id),
    
    -- Pricing and availability
    price_cents INTEGER DEFAULT 0, -- 0 for free packs
    is_free BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    is_premium BOOLEAN DEFAULT false,
    
    -- Age and educational info
    age_min INTEGER DEFAULT 3,
    age_max INTEGER DEFAULT 12,
    educational_goals TEXT[], -- Array of educational objectives
    curriculum_tags TEXT[], -- STEM, Social-Emotional, etc.
    
    -- Visual and metadata
    thumbnail_url TEXT,
    preview_urls TEXT[], -- Array of preview image URLs
    banner_image_url TEXT,
    color_palette JSONB, -- Primary colors used in the pack
    art_style VARCHAR(100), -- Cartoon, Realistic, Minimalist, etc.
    mood_tags TEXT[], -- Happy, Calm, Energetic, etc.
    
    -- Technical metadata
    total_assets INTEGER DEFAULT 0,
    file_size_bytes BIGINT DEFAULT 0,
    supported_platforms TEXT[] DEFAULT '{ios,android,web}',
    min_app_version VARCHAR(20),
    performance_tier VARCHAR(20) DEFAULT 'standard', -- low, standard, high
    
    -- Status and timestamps
    status VARCHAR(50) DEFAULT 'draft', -- draft, review, approved, published, archived
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by UUID, -- Reference to admin user who created it
    
    -- Search and discovery
    search_keywords TEXT,
    popularity_score DECIMAL(5,2) DEFAULT 0.0,
    download_count BIGINT DEFAULT 0,
    rating_average DECIMAL(3,2) DEFAULT 0.0,
    rating_count INTEGER DEFAULT 0
);

-- Individual assets within content packs
CREATE TABLE IF NOT EXISTS content_pack_assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pack_id UUID NOT NULL REFERENCES content_packs(id) ON DELETE CASCADE,
    
    -- Basic asset info
    name VARCHAR(200) NOT NULL,
    description TEXT,
    asset_type media_type NOT NULL,
    file_url TEXT NOT NULL,
    thumbnail_url TEXT,
    
    -- File technical details
    file_format VARCHAR(20), -- png, jpg, gif, mp3, mp4, etc.
    file_size_bytes INTEGER,
    dimensions_width INTEGER,
    dimensions_height INTEGER,
    duration_seconds DECIMAL(8,2), -- For audio/video
    frame_rate INTEGER, -- For animations
    
    -- Creative metadata
    tags TEXT[],
    color_palette JSONB,
    transparency_support BOOLEAN DEFAULT false,
    loop_points JSONB, -- For animations: {start: 0, end: 30}
    
    -- Interactive properties (for interactive objects)
    interaction_config JSONB, -- Configuration for interactive behaviors
    animation_triggers TEXT[], -- Events that can trigger animations
    
    -- Ordering and grouping
    display_order INTEGER DEFAULT 0,
    group_name VARCHAR(100), -- Logical grouping within pack
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User pack ownership and downloads
CREATE TABLE IF NOT EXISTS user_pack_ownership (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL, -- Reference to family.family_members or users table
    pack_id UUID NOT NULL REFERENCES content_packs(id),
    child_id UUID, -- Which child this pack is for (if child-specific)
    
    -- Purchase/acquisition info
    acquired_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    acquisition_type VARCHAR(50) DEFAULT 'purchase', -- purchase, gift, promo, free
    purchase_price_cents INTEGER DEFAULT 0,
    transaction_id VARCHAR(100), -- External payment system reference
    
    -- Download and usage
    download_status VARCHAR(50) DEFAULT 'pending', -- pending, downloading, completed, failed
    download_progress INTEGER DEFAULT 0, -- 0-100
    downloaded_at TIMESTAMP,
    last_used_at TIMESTAMP,
    usage_count INTEGER DEFAULT 0,
    
    -- Preferences
    is_favorite BOOLEAN DEFAULT false,
    is_hidden BOOLEAN DEFAULT false,
    custom_tags TEXT[],
    
    UNIQUE(user_id, pack_id, child_id)
);

-- Pack usage tracking (for analytics)
CREATE TABLE IF NOT EXISTS content_pack_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    child_id UUID,
    pack_id UUID NOT NULL REFERENCES content_packs(id),
    asset_id UUID REFERENCES content_pack_assets(id),
    
    -- Usage context
    used_in_feature VARCHAR(100), -- ai_story, sticker_book, etc.
    session_id UUID, -- Link to user session
    usage_duration_seconds INTEGER,
    
    -- Metadata
    used_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    usage_metadata JSONB -- Feature-specific usage data
);

-- Pack collections/bundles (grouping multiple packs)
CREATE TABLE IF NOT EXISTS content_pack_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(200) NOT NULL,
    description TEXT,
    collection_type VARCHAR(50) DEFAULT 'bundle', -- bundle, seasonal, educational
    
    -- Pricing and availability
    price_cents INTEGER DEFAULT 0,
    discount_percentage INTEGER DEFAULT 0,
    
    -- Visual
    thumbnail_url TEXT,
    banner_image_url TEXT,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    is_featured BOOLEAN DEFAULT false,
    available_from TIMESTAMP,
    available_until TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Many-to-many relationship between collections and packs
CREATE TABLE IF NOT EXISTS content_pack_collection_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES content_pack_collections(id) ON DELETE CASCADE,
    pack_id UUID NOT NULL REFERENCES content_packs(id) ON DELETE CASCADE,
    display_order INTEGER DEFAULT 0,
    added_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(collection_id, pack_id)
);

-- User reviews and ratings (parent-only, COPPA compliant)
CREATE TABLE IF NOT EXISTS content_pack_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pack_id UUID NOT NULL REFERENCES content_packs(id),
    user_id UUID NOT NULL, -- Parent/guardian only
    
    -- Review content
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    review_title VARCHAR(200),
    
    -- Helpful metrics
    helpful_count INTEGER DEFAULT 0,
    not_helpful_count INTEGER DEFAULT 0,
    
    -- Child context (anonymous)
    child_age_range VARCHAR(10), -- "3-5", "6-8", etc.
    used_features TEXT[], -- Which features child used pack with
    
    -- Moderation
    is_approved BOOLEAN DEFAULT false,
    is_featured BOOLEAN DEFAULT false,
    moderated_at TIMESTAMP,
    moderated_by UUID,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(pack_id, user_id)
);

-- Pack compatibility matrix (which packs work well together)
CREATE TABLE IF NOT EXISTS content_pack_compatibility (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pack_a_id UUID NOT NULL REFERENCES content_packs(id),
    pack_b_id UUID NOT NULL REFERENCES content_packs(id),
    compatibility_score DECIMAL(3,2) DEFAULT 1.0, -- 0.0 to 1.0
    compatibility_type VARCHAR(50), -- visual, thematic, educational
    notes TEXT,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(pack_a_id, pack_b_id),
    CHECK (pack_a_id != pack_b_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_content_packs_category ON content_packs(category_id);
CREATE INDEX IF NOT EXISTS idx_content_packs_type ON content_packs(pack_type);
CREATE INDEX IF NOT EXISTS idx_content_packs_status_published ON content_packs(status, published_at);
CREATE INDEX IF NOT EXISTS idx_content_packs_price ON content_packs(price_cents);
CREATE INDEX IF NOT EXISTS idx_content_packs_age_range ON content_packs(age_min, age_max);
CREATE INDEX IF NOT EXISTS idx_content_packs_featured ON content_packs(is_featured, popularity_score);

CREATE INDEX IF NOT EXISTS idx_content_pack_assets_pack ON content_pack_assets(pack_id);
CREATE INDEX IF NOT EXISTS idx_content_pack_assets_type ON content_pack_assets(asset_type);
CREATE INDEX IF NOT EXISTS idx_content_pack_assets_active ON content_pack_assets(is_active);

CREATE INDEX IF NOT EXISTS idx_user_pack_ownership_user ON user_pack_ownership(user_id);
CREATE INDEX IF NOT EXISTS idx_user_pack_ownership_child ON user_pack_ownership(child_id);
CREATE INDEX IF NOT EXISTS idx_user_pack_ownership_pack ON user_pack_ownership(pack_id);
CREATE INDEX IF NOT EXISTS idx_user_pack_ownership_status ON user_pack_ownership(download_status);

CREATE INDEX IF NOT EXISTS idx_content_pack_usage_user_child ON content_pack_usage(user_id, child_id);
CREATE INDEX IF NOT EXISTS idx_content_pack_usage_pack ON content_pack_usage(pack_id);
CREATE INDEX IF NOT EXISTS idx_content_pack_usage_feature ON content_pack_usage(used_in_feature);
CREATE INDEX IF NOT EXISTS idx_content_pack_usage_timestamp ON content_pack_usage(used_at);

-- Full-text search indexes
CREATE INDEX IF NOT EXISTS idx_content_packs_search ON content_packs USING gin(to_tsvector('english', name || ' ' || description || ' ' || COALESCE(search_keywords, '')));
CREATE INDEX IF NOT EXISTS idx_content_pack_assets_search ON content_pack_assets USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- Insert default categories
INSERT INTO content_pack_categories (name, description, display_order, icon_url, color_hex, age_min, age_max) VALUES
('Animals & Nature', 'Cute animals, forests, oceans, and natural environments', 1, '/icons/animals.svg', '#4CAF50', 3, 12),
('Fantasy & Magic', 'Dragons, unicorns, castles, and magical worlds', 2, '/icons/fantasy.svg', '#9C27B0', 4, 12),
('Transportation', 'Cars, trains, planes, boats, and vehicles', 3, '/icons/transport.svg', '#2196F3', 3, 10),
('Space & Science', 'Planets, rockets, robots, and scientific exploration', 4, '/icons/space.svg', '#FF9800', 5, 12),
('Everyday Life', 'Family, home, school, community, and daily activities', 5, '/icons/daily.svg', '#795548', 3, 12),
('Sports & Activities', 'Games, sports, music, dance, and active play', 6, '/icons/sports.svg', '#F44336', 4, 12),
('Educational', 'Letters, numbers, shapes, colors, and learning tools', 7, '/icons/education.svg', '#673AB7', 3, 12),
('Seasonal', 'Holidays, seasons, weather, and special occasions', 8, '/icons/seasonal.svg', '#FF5722', 3, 12)
ON CONFLICT (name) DO NOTHING;

-- Update timestamps function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add triggers for updated_at
CREATE TRIGGER update_content_pack_categories_updated_at BEFORE UPDATE ON content_pack_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_content_packs_updated_at BEFORE UPDATE ON content_packs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_content_pack_assets_updated_at BEFORE UPDATE ON content_pack_assets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_content_pack_collections_updated_at BEFORE UPDATE ON content_pack_collections FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_content_pack_reviews_updated_at BEFORE UPDATE ON content_pack_reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();