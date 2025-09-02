# Content Packs Marketplace - Rich Media Technical Architecture

## Enhanced Database Schema for Rich Media

### Extended Pack Assets Table with Rich Media Support

```sql
-- Enhanced pack_assets table supporting all media types
ALTER TABLE marketplace.pack_assets 
ADD COLUMN media_type VARCHAR(50) NOT NULL DEFAULT 'static_image',
ADD COLUMN technical_metadata JSONB DEFAULT '{}'::jsonb,
ADD COLUMN performance_metadata JSONB DEFAULT '{}'::jsonb,
ADD COLUMN creative_metadata JSONB DEFAULT '{}'::jsonb,
ADD COLUMN educational_metadata JSONB DEFAULT '{}'::jsonb,
ADD COLUMN safety_metadata JSONB DEFAULT '{}'::jsonb,
ADD COLUMN version_metadata JSONB DEFAULT '{}'::jsonb;

-- Create enum for media types
CREATE TYPE marketplace.media_type_enum AS ENUM (
    -- Static Content
    'static_image',
    'vector_graphic',
    'background_image',
    
    -- Animation & Motion
    'sprite_sheet',
    'vector_animation',
    'gif_animation',
    'character_rig',
    'particle_system',
    
    -- Audio Content
    'sound_effect',
    'music_track',
    'voice_sample',
    'ambient_sound',
    
    -- Interactive Elements
    'interactive_object',
    'ui_element',
    'transition_effect',
    
    -- Communication
    'emoji_set',
    'sticker_reaction',
    'speech_bubble',
    'text_effect',
    
    -- 3D & Advanced (Future)
    '3d_model',
    'texture_pack',
    'lighting_preset',
    'camera_movement'
);

ALTER TABLE marketplace.pack_assets 
ALTER COLUMN media_type TYPE marketplace.media_type_enum 
USING media_type::marketplace.media_type_enum;

-- Create indexes for rich media queries
CREATE INDEX idx_pack_assets_media_type ON marketplace.pack_assets (media_type);
CREATE INDEX idx_pack_assets_technical_metadata ON marketplace.pack_assets USING gin(technical_metadata);
CREATE INDEX idx_pack_assets_performance ON marketplace.pack_assets USING gin(performance_metadata);

-- Rich media file storage table
CREATE TABLE marketplace.asset_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES marketplace.pack_assets(id) ON DELETE CASCADE,
    
    -- File information
    file_type VARCHAR(50) NOT NULL, -- 'primary', 'thumbnail', 'preview', 'alternate_format'
    file_format VARCHAR(20) NOT NULL, -- 'png', 'webp', 'mp4', 'aac', 'lottie', 'spine'
    file_path VARCHAR(500) NOT NULL,
    cdn_url VARCHAR(500),
    
    -- File specifications
    file_size_bytes INTEGER NOT NULL,
    checksum VARCHAR(64) NOT NULL, -- SHA-256 for integrity verification
    
    -- Media-specific metadata
    dimensions VARCHAR(20), -- '1024x1024' for images/videos
    duration_ms INTEGER, -- For audio/video content
    frame_rate DECIMAL(6,2), -- For animations
    quality_level VARCHAR(20), -- 'low', 'medium', 'high', 'original'
    
    -- Compression and optimization
    compression_ratio DECIMAL(5,2),
    optimization_applied TEXT[], -- ['webp_conversion', 'audio_normalization', 'sprite_packing']
    
    -- Platform compatibility
    ios_compatible BOOLEAN NOT NULL DEFAULT true,
    android_compatible BOOLEAN NOT NULL DEFAULT true,
    web_compatible BOOLEAN NOT NULL DEFAULT true,
    desktop_compatible BOOLEAN NOT NULL DEFAULT true,
    
    -- Processing status
    processing_status VARCHAR(50) NOT NULL DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    processing_error TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_asset_files_asset ON marketplace.asset_files (asset_id, file_type);
CREATE INDEX idx_asset_files_processing ON marketplace.asset_files (processing_status);

-- Technical metadata standardization for different media types
CREATE TABLE marketplace.media_type_schemas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    media_type marketplace.media_type_enum NOT NULL,
    schema_version VARCHAR(20) NOT NULL,
    
    -- JSON Schema for validating technical_metadata
    technical_schema JSONB NOT NULL,
    performance_schema JSONB NOT NULL,
    creative_schema JSONB NOT NULL,
    educational_schema JSONB NOT NULL,
    safety_schema JSONB NOT NULL,
    
    -- Schema documentation
    description TEXT,
    example_metadata JSONB,
    validation_rules JSONB,
    
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Insert schema definitions for each media type
INSERT INTO marketplace.media_type_schemas (media_type, schema_version, technical_schema, performance_schema, creative_schema, educational_schema, safety_schema, description, example_metadata) VALUES

-- Sprite Sheet Schema
('sprite_sheet', '1.0.0', 
    '{"frame_count": {"type": "integer", "minimum": 1}, "frame_width": {"type": "integer", "minimum": 1}, "frame_height": {"type": "integer", "minimum": 1}, "animation_fps": {"type": "number", "minimum": 1, "maximum": 60}, "loop_type": {"type": "string", "enum": ["once", "loop", "bounce"]}}',
    '{"estimated_memory_mb": {"type": "number"}, "gpu_accelerated": {"type": "boolean"}, "target_fps": {"type": "integer"}, "performance_tier": {"type": "string", "enum": ["low", "medium", "high"]}}',
    '{"animation_style": {"type": "string"}, "color_palette": {"type": "array"}, "mood_tags": {"type": "array"}, "cultural_context": {"type": "string"}}',
    '{"learning_objectives": {"type": "array"}, "age_appropriateness": {"type": "object"}, "skill_development": {"type": "array"}}',
    '{"epilepsy_safe": {"type": "boolean"}, "motion_intensity": {"type": "string", "enum": ["low", "medium", "high"]}, "content_warnings": {"type": "array"}}',
    'Sprite sheet animation metadata for character and object animations',
    '{"frame_count": 24, "frame_width": 128, "frame_height": 128, "animation_fps": 12, "loop_type": "loop", "estimated_memory_mb": 2.5, "epilepsy_safe": true}'
),

-- Vector Animation Schema  
('vector_animation', '1.0.0',
    '{"lottie_version": {"type": "string"}, "duration_seconds": {"type": "number"}, "composition_size": {"type": "object"}, "has_audio": {"type": "boolean"}, "scalable": {"type": "boolean"}}',
    '{"file_size_kb": {"type": "number"}, "complexity_score": {"type": "integer", "minimum": 1, "maximum": 10}, "render_time_ms": {"type": "number"}}',
    '{"animation_type": {"type": "string"}, "style_tags": {"type": "array"}, "color_scheme": {"type": "string"}}',
    '{"demonstrates_concepts": {"type": "array"}, "interactive_elements": {"type": "boolean"}, "educational_context": {"type": "string"}}',
    '{"no_flashing": {"type": "boolean"}, "smooth_transitions": {"type": "boolean"}, "attention_appropriate": {"type": "boolean"}}',
    'Lottie vector animation metadata for scalable motion graphics',
    '{"lottie_version": "5.7.0", "duration_seconds": 3.2, "scalable": true, "complexity_score": 4, "no_flashing": true}'
),

-- Sound Effect Schema
('sound_effect', '1.0.0',
    '{"sample_rate": {"type": "integer"}, "bit_depth": {"type": "integer"}, "channels": {"type": "integer"}, "format": {"type": "string"}, "duration_ms": {"type": "integer"}}',
    '{"file_size_kb": {"type": "number"}, "compression_ratio": {"type": "number"}, "peak_volume_db": {"type": "number"}, "normalized": {"type": "boolean"}}',
    '{"sound_category": {"type": "string"}, "mood": {"type": "string"}, "intensity": {"type": "string"}, "cultural_context": {"type": "string"}}',
    '{"phonetic_learning": {"type": "boolean"}, "cause_effect_teaching": {"type": "boolean"}, "vocabulary_support": {"type": "array"}}',
    '{"volume_limited": {"type": "boolean"}, "no_startling_sounds": {"type": "boolean"}, "hearing_safe": {"type": "boolean"}, "content_appropriate": {"type": "boolean"}}',
    'Sound effect metadata for audio enhancement',
    '{"sample_rate": 44100, "format": "aac", "duration_ms": 1500, "volume_limited": true, "sound_category": "nature"}'
),

-- Interactive Object Schema
('interactive_object', '1.0.0',
    '{"interaction_types": {"type": "array"}, "physics_enabled": {"type": "boolean"}, "state_count": {"type": "integer"}, "animation_states": {"type": "array"}}',
    '{"cpu_cost_score": {"type": "integer"}, "memory_usage_mb": {"type": "number"}, "touch_response_ms": {"type": "number"}}',
    '{"object_theme": {"type": "string"}, "visual_style": {"type": "string"}, "interaction_affordances": {"type": "array"}}',
    '{"motor_skills_development": {"type": "array"}, "cognitive_concepts": {"type": "array"}, "problem_solving_elements": {"type": "boolean"}}',
    '{"safe_interactions": {"type": "boolean"}, "no_addiction_patterns": {"type": "boolean"}, "frustration_mitigation": {"type": "boolean"}}',
    'Interactive object metadata for educational manipulatives',
    '{"interaction_types": ["tap", "drag", "rotate"], "physics_enabled": true, "motor_skills_development": ["fine_motor", "hand_eye_coordination"]}'
);

-- Content pack compatibility matrix for rich media
CREATE TABLE marketplace.feature_media_compatibility (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_name VARCHAR(50) NOT NULL, -- 'sticker_book', 'ai_story', 'story_adventure'
    media_type marketplace.media_type_enum NOT NULL,
    
    -- Compatibility details
    is_supported BOOLEAN NOT NULL DEFAULT false,
    implementation_status VARCHAR(50) NOT NULL DEFAULT 'planned', -- 'available', 'beta', 'planned', 'not_supported'
    performance_impact VARCHAR(50), -- 'none', 'low', 'medium', 'high'
    
    -- Integration metadata
    usage_context TEXT[], -- How this media type is used in this feature
    technical_requirements JSONB, -- Special requirements for this combination
    user_experience_notes TEXT,
    
    -- Version tracking
    supported_since_version VARCHAR(20),
    deprecated_in_version VARCHAR(20),
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_feature_media_compatibility_unique 
ON marketplace.feature_media_compatibility (feature_name, media_type);

-- Insert compatibility matrix data
INSERT INTO marketplace.feature_media_compatibility (feature_name, media_type, is_supported, implementation_status, performance_impact, usage_context, supported_since_version) VALUES
-- Sticker Book Compatibility
('sticker_book', 'static_image', true, 'available', 'none', '["background_placement", "sticker_asset", "decorative_element"]', '1.0.0'),
('sticker_book', 'sprite_sheet', true, 'available', 'low', '["animated_sticker", "character_expression", "interactive_element"]', '1.2.0'),
('sticker_book', 'sound_effect', true, 'beta', 'low', '["sticker_placement_feedback", "interaction_sounds", "ambient_enhancement"]', '1.3.0'),
('sticker_book', 'interactive_object', false, 'planned', 'medium', '["manipulatable_sticker", "physics_interaction"]', '2.0.0'),

-- AI Story Compatibility  
('ai_story', 'static_image', true, 'available', 'none', '["character_illustration", "scene_background", "story_element"]', '1.0.0'),
('ai_story', 'sprite_sheet', true, 'available', 'low', '["character_animation", "scene_transition", "emotional_expression"]', '1.1.0'),
('ai_story', 'sound_effect', true, 'available', 'low', '["narrative_enhancement", "character_voice", "environmental_sound"]', '1.1.0'),
('ai_story', 'voice_sample', true, 'beta', 'medium', '["character_narration", "dialogue_reading"]', '1.4.0'),
('ai_story', 'vector_animation', false, 'planned', 'medium', '["scene_transitions", "magical_effects"]', '2.0.0'),

-- Story Adventure Compatibility
('story_adventure', 'static_image', true, 'available', 'none', '["scene_background", "character_portrait", "item_icon"]', '1.0.0'),
('story_adventure', 'interactive_object', true, 'beta', 'high', '["clickable_hotspot", "puzzle_element", "discovery_object"]', '1.5.0'),
('story_adventure', 'sound_effect', true, 'available', 'low', '["action_feedback", "environmental_ambience", "success_celebration"]', '1.2.0'),
('story_adventure', 'particle_system', false, 'planned', 'high', '["magical_effects", "achievement_celebration", "interaction_feedback"]', '2.1.0');
```

### Performance Optimization Tables

```sql
-- Device performance profiling for adaptive content delivery
CREATE TABLE marketplace.device_performance_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Device identification (anonymized)
    device_category VARCHAR(50) NOT NULL, -- 'high_end_mobile', 'mid_range_mobile', 'low_end_mobile', 'tablet', 'desktop'
    platform VARCHAR(20) NOT NULL, -- 'ios', 'android', 'web', 'macos', 'windows'
    
    -- Performance capabilities
    max_memory_mb INTEGER NOT NULL,
    gpu_tier VARCHAR(20) NOT NULL, -- 'high', 'medium', 'low', 'integrated'
    cpu_score INTEGER, -- Benchmark score for processing capability
    
    -- Media type support matrix
    supported_media_types marketplace.media_type_enum[] NOT NULL,
    performance_limits JSONB NOT NULL, -- Max file sizes, concurrent animations, etc.
    
    -- Quality recommendations
    recommended_quality_settings JSONB NOT NULL,
    fallback_media_types JSONB NOT NULL, -- What to use if primary type not supported
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Content delivery optimization
CREATE TABLE marketplace.asset_delivery_optimization (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES marketplace.pack_assets(id),
    
    -- Delivery variants
    quality_variants JSONB NOT NULL, -- Different quality levels available
    format_variants JSONB NOT NULL, -- Different format options (webp vs png, etc.)
    compression_variants JSONB NOT NULL, -- Different compression levels
    
    -- Caching strategy
    cache_priority VARCHAR(20) NOT NULL DEFAULT 'standard', -- 'critical', 'high', 'standard', 'low'
    preload_recommendation BOOLEAN NOT NULL DEFAULT false,
    cdn_distribution_tier VARCHAR(20) NOT NULL DEFAULT 'standard',
    
    -- Usage analytics for optimization
    download_frequency INTEGER NOT NULL DEFAULT 0,
    average_load_time_ms INTEGER,
    success_rate DECIMAL(5,2) NOT NULL DEFAULT 100.00,
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_asset_delivery_optimization_asset ON marketplace.asset_delivery_optimization (asset_id);
CREATE INDEX idx_asset_delivery_optimization_priority ON marketplace.asset_delivery_optimization (cache_priority);
```

### Rich Media Usage Analytics

```sql
-- Enhanced analytics for rich media usage patterns
CREATE TABLE marketplace.rich_media_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Usage identification
    pack_id UUID NOT NULL REFERENCES marketplace.content_packs(id),
    asset_id UUID NOT NULL REFERENCES marketplace.pack_assets(id),
    family_id UUID NOT NULL,
    child_id UUID,
    session_id UUID,
    
    -- Media-specific metrics
    media_type marketplace.media_type_enum NOT NULL,
    interaction_type VARCHAR(50), -- 'view', 'play', 'interact', 'animate', 'loop'
    duration_engaged_ms INTEGER,
    completion_percentage DECIMAL(5,2),
    
    -- Quality and performance metrics
    quality_level_used VARCHAR(20),
    load_time_ms INTEGER,
    performance_issues TEXT[],
    user_quality_adjustment BOOLEAN DEFAULT false,
    
    -- Educational value tracking
    learning_moment_triggered BOOLEAN DEFAULT false,
    educational_context VARCHAR(100),
    skill_practiced TEXT[],
    
    -- Engagement quality
    repeated_interaction BOOLEAN DEFAULT false,
    creative_application BOOLEAN DEFAULT false, -- Used asset in creative work
    sharing_behavior BOOLEAN DEFAULT false,
    
    -- Device and technical context
    device_type VARCHAR(50),
    network_quality VARCHAR(20), -- 'wifi', 'cellular_good', 'cellular_poor', 'offline'
    battery_level INTEGER, -- For performance impact analysis
    
    used_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

-- Partitioned by month for performance
CREATE INDEX idx_rich_media_analytics_pack ON marketplace.rich_media_analytics (pack_id, used_at);
CREATE INDEX idx_rich_media_analytics_media_type ON marketplace.rich_media_analytics (media_type, used_at);
CREATE INDEX idx_rich_media_analytics_child ON marketplace.rich_media_analytics (child_id, media_type);

-- Aggregate performance metrics table
CREATE TABLE marketplace.media_type_performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Metric identification
    media_type marketplace.media_type_enum NOT NULL,
    device_category VARCHAR(50) NOT NULL,
    time_period DATE NOT NULL, -- Daily aggregation
    
    -- Performance metrics
    average_load_time_ms DECIMAL(10,2),
    success_rate_percentage DECIMAL(5,2),
    average_engagement_duration_ms DECIMAL(12,2),
    completion_rate_percentage DECIMAL(5,2),
    
    -- Usage patterns
    total_interactions INTEGER NOT NULL DEFAULT 0,
    unique_users INTEGER NOT NULL DEFAULT 0,
    peak_concurrent_usage INTEGER NOT NULL DEFAULT 0,
    
    -- Quality metrics
    quality_downgrades INTEGER NOT NULL DEFAULT 0,
    performance_complaints INTEGER NOT NULL DEFAULT 0,
    user_satisfaction_score DECIMAL(3,2),
    
    -- Resource usage
    average_memory_usage_mb DECIMAL(8,2),
    average_cpu_usage_percentage DECIMAL(5,2),
    network_data_usage_mb DECIMAL(10,2),
    
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_media_performance_metrics_unique 
ON marketplace.media_type_performance_metrics (media_type, device_category, time_period);
```

This enhanced database schema provides comprehensive support for rich media types while maintaining performance optimization and detailed analytics tracking. The system can handle everything from simple static images to complex interactive 3D content (for future phases) while ensuring child safety and educational value measurement throughout.