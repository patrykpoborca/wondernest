-- V6__Refactor_Story_Adventure_Plugin.sql
-- Refactor Story Adventure to follow WonderNest's proper plugin architecture
-- This migration converts child-specific tables to use games.simple_game_data with JSONB
-- while keeping platform-level tables (templates, marketplace) as dedicated tables

SET search_path TO games, public;

-- =============================================================================
-- DATA MIGRATION: STORY INSTANCES → SIMPLE_GAME_DATA
-- =============================================================================

-- Migrate existing story instances to simple_game_data using game_type = 'story-adventure'
-- Each active story becomes a separate data entry with key pattern: story_instance:{template_id}

INSERT INTO games.simple_game_data (
    child_id,
    game_type,
    data_key,
    data_value,
    created_at,
    updated_at
)
SELECT 
    si.child_id,
    'story-adventure',
    'story_instance:' || si.template_id::text,
    jsonb_build_object(
        'instanceId', si.id::text,
        'templateId', si.template_id::text,
        'status', si.status,
        'currentPage', si.current_page,
        'totalPages', si.total_pages,
        'customizations', si.customizations,
        'readingMode', si.reading_mode,
        'audioEnabled', si.audio_enabled,
        'progressData', si.progress_data,
        'vocabularyInteractions', si.vocabulary_interactions,
        'comprehensionAnswers', si.comprehension_answers,
        'startedAt', extract(epoch from si.started_at)::bigint,
        'lastAccessedAt', extract(epoch from si.last_accessed_at)::bigint,
        'completedAt', CASE WHEN si.completed_at IS NOT NULL THEN extract(epoch from si.completed_at)::bigint ELSE NULL END,
        'totalReadingTime', si.total_reading_time,
        'readingSpeedWpm', si.reading_speed_wpm,
        'comprehensionScore', si.comprehension_score,
        'vocabularyScore', si.vocabulary_score,
        'migratedFrom', 'story_instances',
        'migrationDate', extract(epoch from CURRENT_TIMESTAMP)::bigint
    ),
    si.started_at,
    si.last_accessed_at
FROM games.story_instances si
WHERE si.status IN ('in_progress', 'completed')
ON CONFLICT (child_id, game_type, data_key) DO UPDATE SET
    data_value = EXCLUDED.data_value,
    updated_at = EXCLUDED.updated_at;

-- Create story history entry for each child (aggregate of completed stories)
INSERT INTO games.simple_game_data (
    child_id,
    game_type,
    data_key,
    data_value,
    created_at,
    updated_at
)
SELECT 
    si.child_id,
    'story-adventure',
    'story_history',
    jsonb_build_object(
        'completedStories', jsonb_agg(
            jsonb_build_object(
                'templateId', si.template_id::text,
                'completedAt', extract(epoch from si.completed_at)::bigint,
                'totalReadingTime', si.total_reading_time,
                'comprehensionScore', si.comprehension_score,
                'vocabularyScore', si.vocabulary_score,
                'readingSpeedWpm', si.reading_speed_wpm
            )
            ORDER BY si.completed_at DESC
        ),
        'totalCompletedStories', count(*),
        'totalReadingTime', sum(si.total_reading_time),
        'averageComprehensionScore', round(avg(si.comprehension_score), 2),
        'averageVocabularyScore', round(avg(si.vocabulary_score), 2),
        'lastUpdated', extract(epoch from max(si.completed_at))::bigint,
        'migratedFrom', 'story_instances',
        'migrationDate', extract(epoch from CURRENT_TIMESTAMP)::bigint
    ),
    min(si.started_at),
    max(si.last_accessed_at)
FROM games.story_instances si
WHERE si.status = 'completed'
GROUP BY si.child_id
HAVING count(*) > 0
ON CONFLICT (child_id, game_type, data_key) DO UPDATE SET
    data_value = EXCLUDED.data_value,
    updated_at = EXCLUDED.updated_at;

-- =============================================================================
-- DATA MIGRATION: VOCABULARY PROGRESS → SIMPLE_GAME_DATA
-- =============================================================================

-- Migrate vocabulary progress to simple_game_data with key 'vocabulary_progress'
INSERT INTO games.simple_game_data (
    child_id,
    game_type,
    data_key,
    data_value,
    created_at,
    updated_at
)
SELECT 
    vp.child_id,
    'story-adventure',
    'vocabulary_progress',
    jsonb_build_object(
        'words', jsonb_object_agg(
            vp.word,
            jsonb_build_object(
                'encounters', vp.encounters,
                'correctUses', vp.correct_uses,
                'incorrectUses', vp.incorrect_uses,
                'masteryLevel', vp.mastery_level,
                'lastSeenIn', vp.last_seen_in::text,
                'definitionViewedCount', vp.definition_viewed_count,
                'pronunciationPlayedCount', vp.pronunciation_played_count,
                'firstEncountered', extract(epoch from vp.first_encountered)::bigint,
                'lastEncountered', extract(epoch from vp.last_encountered)::bigint,
                'masteredAt', CASE WHEN vp.mastered_at IS NOT NULL THEN extract(epoch from vp.mastered_at)::bigint ELSE NULL END
            )
        ),
        'totalWords', count(*),
        'masteredWords', count(*) FILTER (WHERE vp.mastery_level >= 80),
        'averageMasteryLevel', round(avg(vp.mastery_level), 2),
        'lastUpdated', extract(epoch from max(vp.last_encountered))::bigint,
        'migratedFrom', 'vocabulary_progress',
        'migrationDate', extract(epoch from CURRENT_TIMESTAMP)::bigint
    ),
    min(vp.first_encountered),
    max(vp.last_encountered)
FROM games.vocabulary_progress vp
GROUP BY vp.child_id
HAVING count(*) > 0
ON CONFLICT (child_id, game_type, data_key) DO UPDATE SET
    data_value = EXCLUDED.data_value,
    updated_at = EXCLUDED.updated_at;

-- =============================================================================
-- DATA MIGRATION: STORY ANALYTICS → SIMPLE_GAME_DATA
-- =============================================================================

-- Migrate story analytics to simple_game_data with key 'reading_analytics'
-- Aggregate analytics data by child for performance and privacy
INSERT INTO games.simple_game_data (
    child_id,
    game_type,
    data_key,
    data_value,
    created_at,
    updated_at
)
SELECT 
    sa.child_id,
    'story-adventure',
    'reading_analytics',
    jsonb_build_object(
        'totalEvents', count(*),
        'eventsByType', (
            SELECT jsonb_object_agg(event_type, event_count)
            FROM (
                SELECT event_type, count(*) as event_count
                FROM games.story_analytics sa2
                WHERE sa2.child_id = sa.child_id
                GROUP BY event_type
            ) type_counts
        ),
        'eventsByCategory', (
            SELECT jsonb_object_agg(event_category, event_count)
            FROM (
                SELECT event_category, count(*) as event_count
                FROM games.story_analytics sa3
                WHERE sa3.child_id = sa.child_id AND event_category IS NOT NULL
                GROUP BY event_category
            ) category_counts
        ),
        'sessionsCount', count(DISTINCT sa.session_id),
        'templatesEngaged', count(DISTINCT sa.template_id),
        'deviceTypes', array_agg(DISTINCT sa.device_type) FILTER (WHERE sa.device_type IS NOT NULL),
        'lastEventAt', extract(epoch from max(sa.created_at))::bigint,
        'firstEventAt', extract(epoch from min(sa.created_at))::bigint,
        'averageSessionLength', COALESCE((
            SELECT round(avg(session_length), 2)
            FROM (
                SELECT 
                    EXTRACT(EPOCH FROM (max(created_at) - min(created_at)))/60 as session_length
                FROM games.story_analytics sa4
                WHERE sa4.child_id = sa.child_id AND session_id IS NOT NULL
                GROUP BY session_id
                HAVING count(*) > 1
            ) session_lengths
        ), 0),
        'mostActivePages', array_agg(DISTINCT sa.page_number ORDER BY sa.page_number) FILTER (WHERE sa.page_number IS NOT NULL),
        'migratedFrom', 'story_analytics',
        'migrationDate', extract(epoch from CURRENT_TIMESTAMP)::bigint
    ),
    min(sa.created_at),
    max(sa.created_at)
FROM games.story_analytics sa
GROUP BY sa.child_id
HAVING count(*) > 0
ON CONFLICT (child_id, game_type, data_key) DO UPDATE SET
    data_value = EXCLUDED.data_value,
    updated_at = EXCLUDED.updated_at;

-- =============================================================================
-- ADD INDEXES FOR STORY ADVENTURE QUERIES
-- =============================================================================

-- Index for Story Adventure game type queries
CREATE INDEX IF NOT EXISTS idx_simple_game_data_story_adventure 
ON games.simple_game_data(child_id, game_type, data_key)
WHERE game_type = 'story-adventure';

-- GIN index for story instance lookups within JSONB
CREATE INDEX IF NOT EXISTS idx_simple_game_data_story_jsonb
ON games.simple_game_data USING GIN(data_value)
WHERE game_type = 'story-adventure';

-- Index for vocabulary word searches
CREATE INDEX IF NOT EXISTS idx_simple_game_data_vocab_words
ON games.simple_game_data USING GIN((data_value->'words'))
WHERE game_type = 'story-adventure' AND data_key = 'vocabulary_progress';

-- =============================================================================
-- DROP DEPRECATED CHILD-SPECIFIC TABLES
-- =============================================================================

-- These tables are now replaced by simple_game_data with JSONB storage
-- Data has been migrated above, so safe to drop

-- Drop triggers first
DROP TRIGGER IF EXISTS update_story_instances_access ON games.story_instances;
DROP FUNCTION IF EXISTS games.update_story_instance_access();

-- Drop indexes
DROP INDEX IF EXISTS games.idx_story_instances_child;
DROP INDEX IF EXISTS games.idx_story_instances_template;
DROP INDEX IF EXISTS games.idx_story_instances_last_accessed;
DROP INDEX IF EXISTS games.idx_story_instances_progress;

DROP INDEX IF EXISTS games.idx_vocabulary_child_word;
DROP INDEX IF EXISTS games.idx_vocabulary_mastery;
DROP INDEX IF EXISTS games.idx_vocabulary_last_encountered;

DROP INDEX IF EXISTS games.idx_story_analytics_child_date;
DROP INDEX IF EXISTS games.idx_story_analytics_event_type;
DROP INDEX IF EXISTS games.idx_story_analytics_session;
DROP INDEX IF EXISTS games.idx_story_analytics_template;

-- Drop the tables in correct order (child tables first due to foreign key constraints)
DROP TABLE IF EXISTS games.story_analytics CASCADE;  -- Has FK to story_instances
DROP TABLE IF EXISTS games.story_instances CASCADE;   -- Referenced by story_analytics
DROP TABLE IF EXISTS games.vocabulary_progress CASCADE;

-- =============================================================================
-- UPDATE PERMISSIONS
-- =============================================================================

-- Ensure application user has proper permissions on new indexes
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA games TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA games TO wondernest_app;

-- Grant analytics user read permissions
GRANT SELECT ON games.simple_game_data TO wondernest_analytics;

-- =============================================================================
-- ADD COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON INDEX games.idx_simple_game_data_story_adventure IS 
'Index for Story Adventure child data queries by child, game type and data key';

COMMENT ON INDEX games.idx_simple_game_data_story_jsonb IS 
'GIN index for searching within Story Adventure JSONB data values';

COMMENT ON INDEX games.idx_simple_game_data_vocab_words IS 
'GIN index for vocabulary word searches within JSONB vocabulary progress data';

-- =============================================================================
-- UPDATE DATABASE VERSION
-- =============================================================================

-- Record the plugin architecture refactoring
INSERT INTO core.database_info (key, value) 
VALUES ('story_adventure_plugin_version', '2.0.0')
ON CONFLICT (key) DO UPDATE SET 
    value = '2.0.0';

-- Record migration completion
INSERT INTO core.database_info (key, value)
VALUES ('story_adventure_migration_v6_completed', extract(epoch from CURRENT_TIMESTAMP)::text)
ON CONFLICT (key) DO UPDATE SET 
    value = extract(epoch from CURRENT_TIMESTAMP)::text;

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- These queries can be used to verify the migration was successful
-- Uncomment during development/testing

/*
-- Count migrated child data by key
SELECT 
    data_key,
    count(*) as child_count,
    count(DISTINCT child_id) as unique_children
FROM games.simple_game_data 
WHERE game_type = 'story-adventure'
GROUP BY data_key
ORDER BY child_count DESC;

-- Sample vocabulary data structure
SELECT 
    child_id,
    data_key,
    jsonb_pretty(data_value)
FROM games.simple_game_data 
WHERE data_key = 'vocabulary_progress'
  AND game_type = 'story-adventure'
LIMIT 1;

-- Sample story instance data
SELECT 
    child_id,
    data_key,
    jsonb_pretty(data_value)
FROM games.simple_game_data 
WHERE data_key LIKE 'story_instance:%'
  AND game_type = 'story-adventure'
LIMIT 1;

-- Verify analytics migration
SELECT 
    child_id,
    (data_value->>'totalEvents')::int as total_events,
    (data_value->>'sessionsCount')::int as sessions,
    (data_value->>'templatesEngaged')::int as templates_used
FROM games.simple_game_data 
WHERE data_key = 'reading_analytics'
  AND game_type = 'story-adventure'
ORDER BY total_events DESC
LIMIT 5;
*/