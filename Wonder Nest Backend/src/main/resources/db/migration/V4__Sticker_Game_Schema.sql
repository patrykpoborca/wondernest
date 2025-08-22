-- =============================================================================
-- V4: STICKER GAME SCHEMA - Specific tables for sticker game implementation
-- =============================================================================
-- This migration extends the V3 games schema with sticker-specific tables and data

-- Insert sticker game into the game registry
INSERT INTO games.game_registry (
    id,
    game_key,
    display_name,
    description,
    version,
    game_type_id,
    category_id,
    min_age_months,
    max_age_months,
    configuration,
    default_settings,
    implementation_type,
    content_rating,
    safety_reviewed,
    is_active,
    is_premium,
    tags,
    keywords,
    educational_objectives,
    skills_developed,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'sticker_book',
    'Creative Sticker Book',
    'A creative playground where children can create stories and scenes using digital stickers, drawings, and text.',
    '1.0.0',
    (SELECT id FROM games.game_types WHERE name = 'creative'),
    (SELECT id FROM games.game_categories WHERE name = 'Stickers'),
    24, -- 2 years
    144, -- 12 years
    '{"modes": ["infinite_canvas", "flip_book"], "max_projects": 50, "auto_save": true, "export_formats": ["png", "pdf"]}',
    '{"sound_enabled": true, "animations_enabled": true, "auto_save": true, "tutorial_completed": false, "difficulty": "age_appropriate"}',
    'native',
    'everyone',
    true,
    true,
    false,
    '["creative", "educational", "stickers", "drawing", "art"]',
    '["sticker", "book", "creative", "art", "draw", "canvas", "infinite", "story"]',
    '["creativity", "fine_motor_skills", "storytelling", "artistic_expression", "spatial_awareness"]',
    '["creativity", "fine_motor_development", "artistic_skills", "imagination", "storytelling"]',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
);

-- =============================================================================
-- STICKER GAME SPECIFIC TABLES
-- =============================================================================

-- Sticker sets (collections of themed stickers)
CREATE TABLE games.sticker_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    theme VARCHAR(100) NOT NULL, -- animals, vehicles, food, etc.
    description TEXT,
    sticker_data JSONB NOT NULL, -- Array of sticker definitions
    is_premium BOOLEAN DEFAULT FALSE,
    min_age_months INTEGER DEFAULT 24,
    max_age_months INTEGER DEFAULT 144,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE games.sticker_sets IS 'Collections of themed stickers for the sticker book game';

-- Game templates (predefined scenes or challenges)
CREATE TABLE games.sticker_game_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    background_image_url VARCHAR(500),
    sticker_set_ids JSONB NOT NULL DEFAULT '[]', -- Array of sticker set IDs
    target_age_min INTEGER NOT NULL DEFAULT 24,
    target_age_max INTEGER NOT NULL DEFAULT 144,
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 5) DEFAULT 1,
    template_data JSONB NOT NULL DEFAULT '{}', -- Template-specific configuration
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

COMMENT ON TABLE games.sticker_game_templates IS 'Predefined templates and challenges for the sticker game';

-- Child sticker collections (tracks which stickers/packs a child has unlocked)
CREATE TABLE games.child_sticker_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_id UUID NOT NULL REFERENCES family.child_profiles(id) ON DELETE CASCADE,
    sticker_set_id UUID NOT NULL REFERENCES games.sticker_sets(id) ON DELETE CASCADE,
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    is_favorite BOOLEAN DEFAULT FALSE,
    usage_count INTEGER DEFAULT 0,
    
    UNIQUE(child_id, sticker_set_id)
);

COMMENT ON TABLE games.child_sticker_collections IS 'Tracks which sticker sets each child has unlocked';

-- Sticker book projects (child creations)
CREATE TABLE games.sticker_book_projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    child_game_instance_id UUID NOT NULL REFERENCES games.child_game_instances(id) ON DELETE CASCADE,
    project_name VARCHAR(255) NOT NULL,
    description TEXT,
    creation_mode VARCHAR(50) NOT NULL DEFAULT 'infinite_canvas', -- 'infinite_canvas' or 'flip_book'
    project_data JSONB NOT NULL, -- Full project data (canvas, pages, etc.)
    thumbnail_url VARCHAR(500),
    is_completed BOOLEAN DEFAULT FALSE,
    is_shared BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_modified TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE games.sticker_book_projects IS 'Individual sticker book projects created by children';

-- Project interactions (analytics for specific project usage)
CREATE TABLE games.sticker_project_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES games.sticker_book_projects(id) ON DELETE CASCADE,
    session_id UUID NOT NULL REFERENCES games.game_sessions(id) ON DELETE CASCADE,
    interaction_type VARCHAR(50) NOT NULL, -- 'sticker_placed', 'sticker_moved', 'drawing_added', etc.
    interaction_data JSONB NOT NULL, -- Specific interaction details
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE games.sticker_project_interactions IS 'Detailed interaction tracking for sticker book projects';

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Sticker sets indexes
CREATE INDEX idx_sticker_sets_theme ON games.sticker_sets(theme);
CREATE INDEX idx_sticker_sets_age_range ON games.sticker_sets(min_age_months, max_age_months);
CREATE INDEX idx_sticker_sets_active ON games.sticker_sets(is_active) WHERE is_active = TRUE;

-- Game templates indexes
CREATE INDEX idx_sticker_templates_age_range ON games.sticker_game_templates(target_age_min, target_age_max);
CREATE INDEX idx_sticker_templates_difficulty ON games.sticker_game_templates(difficulty_level);
CREATE INDEX idx_sticker_templates_active ON games.sticker_game_templates(is_active) WHERE is_active = TRUE;

-- Child collections indexes
CREATE INDEX idx_child_sticker_collections_child ON games.child_sticker_collections(child_id);
CREATE INDEX idx_child_sticker_collections_set ON games.child_sticker_collections(sticker_set_id);
CREATE INDEX idx_child_sticker_collections_unlocked ON games.child_sticker_collections(unlocked_at);

-- Projects indexes
CREATE INDEX idx_sticker_projects_instance ON games.sticker_book_projects(child_game_instance_id);
CREATE INDEX idx_sticker_projects_mode ON games.sticker_book_projects(creation_mode);
CREATE INDEX idx_sticker_projects_completed ON games.sticker_book_projects(is_completed);
CREATE INDEX idx_sticker_projects_modified ON games.sticker_book_projects(last_modified);

-- Interactions indexes
CREATE INDEX idx_sticker_interactions_project ON games.sticker_project_interactions(project_id);
CREATE INDEX idx_sticker_interactions_session ON games.sticker_project_interactions(session_id);
CREATE INDEX idx_sticker_interactions_type ON games.sticker_project_interactions(interaction_type);
CREATE INDEX idx_sticker_interactions_timestamp ON games.sticker_project_interactions(timestamp);

-- =============================================================================
-- SAMPLE DATA
-- =============================================================================

-- Insert basic sticker sets
INSERT INTO games.sticker_sets (name, theme, description, sticker_data, is_premium, min_age_months, max_age_months) VALUES
('Farm Animals', 'animals', 'Cute farm animals including cows, pigs, chickens, and horses', 
 '[
   {"id": "cow_1", "name": "Happy Cow", "emoji": "🐄", "category": "animals"},
   {"id": "pig_1", "name": "Little Pig", "emoji": "🐷", "category": "animals"},
   {"id": "chicken_1", "name": "Chicken", "emoji": "🐔", "category": "animals"},
   {"id": "horse_1", "name": "Brown Horse", "emoji": "🐴", "category": "animals"},
   {"id": "sheep_1", "name": "Fluffy Sheep", "emoji": "🐑", "category": "animals"}
 ]', FALSE, 24, 144),

('Basic Shapes', 'shapes', 'Fundamental shapes in bright colors for learning and creativity',
 '[
   {"id": "circle_red", "name": "Red Circle", "emoji": "🔴", "category": "shapes"},
   {"id": "square_blue", "name": "Blue Square", "emoji": "🟦", "category": "shapes"},
   {"id": "triangle_green", "name": "Green Triangle", "emoji": "🔺", "category": "shapes"},
   {"id": "star_yellow", "name": "Yellow Star", "emoji": "⭐", "category": "shapes"},
   {"id": "heart_pink", "name": "Pink Heart", "emoji": "💖", "category": "shapes"}
 ]', FALSE, 24, 72),

('Vehicles', 'vehicles', 'Cars, trucks, planes, and boats for transportation adventures',
 '[
   {"id": "car_red", "name": "Red Car", "emoji": "🚗", "category": "vehicles"},
   {"id": "truck_blue", "name": "Blue Truck", "emoji": "🚚", "category": "vehicles"},
   {"id": "plane_white", "name": "Airplane", "emoji": "✈️", "category": "vehicles"},
   {"id": "boat_yellow", "name": "Yellow Boat", "emoji": "🚤", "category": "vehicles"},
   {"id": "train_green", "name": "Green Train", "emoji": "🚂", "category": "vehicles"}
 ]', FALSE, 36, 144),

('Food Fun', 'food', 'Delicious food items for pretend play and learning about nutrition',
 '[
   {"id": "apple_red", "name": "Red Apple", "emoji": "🍎", "category": "food"},
   {"id": "banana_yellow", "name": "Banana", "emoji": "🍌", "category": "food"},
   {"id": "pizza_slice", "name": "Pizza Slice", "emoji": "🍕", "category": "food"},
   {"id": "cookie_chocolate", "name": "Chocolate Cookie", "emoji": "🍪", "category": "food"},
   {"id": "ice_cream", "name": "Ice Cream", "emoji": "🍦", "category": "food"}
 ]', FALSE, 24, 144);

-- Insert a sample game template
INSERT INTO games.sticker_game_templates (title, description, sticker_set_ids, target_age_min, target_age_max, difficulty_level, template_data) VALUES
('Farm Scene', 'Create a fun farm scene with animals and buildings', 
 '["' || (SELECT id FROM games.sticker_sets WHERE name = 'Farm Animals') || '"]',
 36, 120, 2,
 '{"background": "farm_scene", "suggested_elements": ["barn", "fence", "sun"], "completion_criteria": {"min_stickers": 3}}');

-- Insert basic achievements for the sticker game
INSERT INTO games.achievements (game_id, achievement_key, name, description, criteria, points, category, rarity) VALUES
((SELECT id FROM games.game_registry WHERE game_key = 'sticker_book'), 'first_creation', 'First Creation', 'Create your first sticker book project', '{"type": "projects_created", "threshold": 1}', 10, 'getting_started', 'common'),
((SELECT id FROM games.game_registry WHERE game_key = 'sticker_book'), 'sticker_collector', 'Sticker Collector', 'Use 50 different stickers in your projects', '{"type": "unique_stickers_used", "threshold": 50}', 25, 'collection', 'uncommon'),
((SELECT id FROM games.game_registry WHERE game_key = 'sticker_book'), 'prolific_creator', 'Prolific Creator', 'Create 10 different sticker book projects', '{"type": "projects_created", "threshold": 10}', 50, 'creation', 'rare'),
((SELECT id FROM games.game_registry WHERE game_key = 'sticker_book'), 'artist_extraordinaire', 'Artist Extraordinaire', 'Spend 60 minutes creating in the sticker book', '{"type": "time_played_minutes", "threshold": 60}', 30, 'engagement', 'uncommon');

-- =============================================================================
-- PERMISSIONS
-- =============================================================================

-- Grant permissions for the sticker game tables
GRANT SELECT, INSERT, UPDATE, DELETE ON games.sticker_sets TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON games.sticker_game_templates TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON games.child_sticker_collections TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON games.sticker_book_projects TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON games.sticker_project_interactions TO wondernest_app;

-- =============================================================================
-- FUNCTIONS AND TRIGGERS FOR STICKER GAME
-- =============================================================================

-- Update last_modified trigger for projects
CREATE TRIGGER update_sticker_projects_last_modified
    BEFORE UPDATE ON games.sticker_book_projects
    FOR EACH ROW
    EXECUTE FUNCTION games.update_updated_at();

-- Update template updated_at trigger
CREATE TRIGGER update_sticker_templates_updated_at
    BEFORE UPDATE ON games.sticker_game_templates
    FOR EACH ROW
    EXECUTE FUNCTION games.update_updated_at();

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON SCHEMA games IS 'Enhanced with sticker book game specific tables for creative gameplay and child development tracking';