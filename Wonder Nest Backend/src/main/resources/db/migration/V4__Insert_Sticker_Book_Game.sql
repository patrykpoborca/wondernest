-- V4__Insert_Sticker_Book_Game.sql
-- Insert sticker_book game into GameRegistry following proper architecture
-- This migration adds the sticker_book game to the game registry system

-- =============================================================================
-- INSERT GAME TYPES AND CATEGORIES
-- =============================================================================

-- Insert creative games type if not exists
INSERT INTO games.game_types (id, name, description, default_schema, created_at) VALUES (
    gen_random_uuid(),
    'creative_game',
    'Games that focus on creative expression and art-making activities',
    '{"type": "creative_game", "supports_saving": true, "supports_sharing": true, "data_format": "json"}',
    CURRENT_TIMESTAMP
) ON CONFLICT (name) DO NOTHING;

-- Insert sticker book category if not exists
INSERT INTO games.game_categories (id, name, parent_category_id, icon_url, sort_order, is_active, created_at) VALUES (
    gen_random_uuid(),
    'sticker_books',
    NULL,
    NULL,
    1,
    true,
    CURRENT_TIMESTAMP
) ON CONFLICT (name) DO NOTHING;

-- =============================================================================
-- INSERT STICKER BOOK GAME
-- =============================================================================

-- Insert sticker_book game into GameRegistry
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
    entry_point,
    resource_bundle_url,
    content_rating,
    safety_reviewed,
    safety_reviewed_at,
    is_active,
    is_premium,
    release_date,
    tags,
    keywords,
    educational_objectives,
    skills_developed,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),
    'sticker_book',
    'Sticker Book',
    'Creative digital sticker book where children can place stickers, draw, and create their own artworks',
    '1.0.0',
    (SELECT id FROM games.game_types WHERE name = 'creative_game'),
    (SELECT id FROM games.game_categories WHERE name = 'sticker_books'),
    24, -- 2+ years
    144, -- up to 12 years
    '{
        "supports_infinite_canvas": true,
        "supports_flip_book": true,
        "supports_stickers": true,
        "supports_drawing": true,
        "supports_thumbnails": true,
        "supports_projects": true,
        "max_projects_per_child": 50,
        "auto_save_interval": 30
    }',
    '{
        "age_mode": "big_kid",
        "auto_save_enabled": true,
        "project_naming": "auto",
        "thumbnail_generation": true
    }',
    'native',
    '/games/sticker-book',
    NULL,
    'everyone',
    true,
    CURRENT_TIMESTAMP,
    true,
    false,
    CURRENT_TIMESTAMP,
    '["creative", "art", "stickers", "drawing", "projects"]',
    '["sticker", "creative", "art", "drawing", "digital", "canvas", "flip book", "projects"]',
    '["creative_expression", "fine_motor_skills", "artistic_development", "color_recognition", "spatial_awareness"]',
    '["creativity", "artistic_skills", "fine_motor_control", "visual_planning", "project_completion"]',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (game_key) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    version = EXCLUDED.version,
    configuration = EXCLUDED.configuration,
    default_settings = EXCLUDED.default_settings,
    is_active = EXCLUDED.is_active,
    updated_at = CURRENT_TIMESTAMP;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE games.game_registry IS 'Game registry containing all available games with their metadata and configuration';
COMMENT ON TABLE games.game_types IS 'Game types categorizing games by their primary mechanics and purpose';
COMMENT ON TABLE games.game_categories IS 'Hierarchical categories for organizing games in the UI';

-- Update version info
INSERT INTO core.database_info (key, value) VALUES ('schema_version', '4.0.0')
ON CONFLICT (key) DO UPDATE SET value = '4.0.0';