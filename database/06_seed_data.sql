-- WonderNest Seed Data Script
-- Initial reference data, lookup tables, and sample data for development
--
-- Usage:
--   psql -U postgres -d wondernest_prod -f 06_seed_data.sql
--
-- Prerequisites:
--   - All tables, functions, indexes, and triggers created
--   - Connected to wondernest_prod database

-- =============================================================================
-- SUBSCRIPTION PLANS
-- =============================================================================

-- Create subscription plans
INSERT INTO subscription.plans (id, name, type, display_name, description, price_cents, currency, billing_cycle, features, max_children) VALUES
-- Free Plan
(
    uuid_generate_v4(),
    'wondernest_basic',
    'free',
    'WonderNest Basic',
    'Get started with curated content and basic tracking for one child',
    0,
    'USD',
    'monthly',
    jsonb_build_object(
        'content_hours_per_week', 3,
        'basic_screen_time_tracking', true,
        'weekly_audio_summaries', true,
        'community_access', true,
        'ads_free', true,
        'offline_downloads', false,
        'detailed_analytics', false,
        'professional_tools', false
    ),
    1
),
-- Plus Plan
(
    uuid_generate_v4(),
    'wondernest_plus',
    'plus',
    'WonderNest Plus',
    'Unlock unlimited content, real-time insights, and advanced features for your family',
    1499, -- $14.99
    'USD',
    'monthly',
    jsonb_build_object(
        'content_hours_per_week', -1,
        'real_time_audio_analysis', true,
        'daily_insights', true,
        'offline_downloads', true,
        'priority_support', true,
        'advanced_analytics', true,
        'conversation_prompts', true,
        'milestone_tracking', true,
        'data_export', true,
        'professional_tools', false
    ),
    4
),
-- Pro Plan
(
    uuid_generate_v4(),
    'wondernest_pro',
    'pro',
    'WonderNest Pro',
    'Professional-grade tools for educators, therapists, and advanced users',
    2999, -- $29.99
    'USD',
    'monthly',
    jsonb_build_object(
        'everything_in_plus', true,
        'professional_dashboard', true,
        'clinical_reports', true,
        'telehealth_integration', true,
        'api_access', true,
        'white_label_options', true,
        'priority_phone_support', true,
        'custom_development_plans', true,
        'research_participation', true
    ),
    10
);

-- =============================================================================
-- CONTENT CATEGORIES
-- =============================================================================

-- Root categories
INSERT INTO content.categories (id, parent_id, name, slug, description, sort_order) VALUES
-- Main Categories
(uuid_generate_v4(), NULL, 'Educational', 'educational', 'Content focused on learning and skill development', 1),
(uuid_generate_v4(), NULL, 'Entertainment', 'entertainment', 'Fun and engaging content for enjoyment', 2),
(uuid_generate_v4(), NULL, 'Stories & Books', 'stories-books', 'Interactive stories and digital books', 3),
(uuid_generate_v4(), NULL, 'Music & Songs', 'music-songs', 'Musical content and sing-along activities', 4),
(uuid_generate_v4(), NULL, 'Physical Activity', 'physical-activity', 'Movement and exercise content', 5),
(uuid_generate_v4(), NULL, 'Art & Creativity', 'art-creativity', 'Creative expression and art activities', 6);

-- Educational subcategories
WITH educational_category AS (
    SELECT id FROM content.categories WHERE slug = 'educational'
)
INSERT INTO content.categories (id, parent_id, name, slug, description, sort_order) VALUES
(uuid_generate_v4(), (SELECT id FROM educational_category), 'Math & Numbers', 'math-numbers', 'Counting, basic math, and number recognition', 1),
(uuid_generate_v4(), (SELECT id FROM educational_category), 'Letters & Reading', 'letters-reading', 'Alphabet, phonics, and early reading skills', 2),
(uuid_generate_v4(), (SELECT id FROM educational_category), 'Science & Nature', 'science-nature', 'Exploring the natural world and basic science concepts', 3),
(uuid_generate_v4(), (SELECT id FROM educational_category), 'Social Skills', 'social-skills', 'Interpersonal skills and emotional development', 4),
(uuid_generate_v4(), (SELECT id FROM educational_category), 'Problem Solving', 'problem-solving', 'Logic, puzzles, and critical thinking', 5),
(uuid_generate_v4(), (SELECT id FROM educational_category), 'Language Learning', 'language-learning', 'Second language acquisition and vocabulary', 6);

-- Entertainment subcategories
WITH entertainment_category AS (
    SELECT id FROM content.categories WHERE slug = 'entertainment'
)
INSERT INTO content.categories (id, parent_id, name, slug, description, sort_order) VALUES
(uuid_generate_v4(), (SELECT id FROM entertainment_category), 'Adventure', 'adventure', 'Exciting journeys and exploration stories', 1),
(uuid_generate_v4(), (SELECT id FROM entertainment_category), 'Comedy', 'comedy', 'Funny and humorous content', 2),
(uuid_generate_v4(), (SELECT id FROM entertainment_category), 'Fantasy', 'fantasy', 'Magical and imaginative stories', 3),
(uuid_generate_v4(), (SELECT id FROM entertainment_category), 'Animals', 'animals', 'Content featuring animals and pets', 4);

-- =============================================================================
-- CONTENT CREATORS
-- =============================================================================

INSERT INTO content.creators (id, name, slug, description, website_url, is_verified) VALUES
-- Educational Creators
(
    uuid_generate_v4(),
    'PBS Kids',
    'pbs-kids',
    'Public Broadcasting Service educational content for children',
    'https://pbskids.org',
    true
),
(
    uuid_generate_v4(),
    'Sesame Workshop',
    'sesame-workshop',
    'Creators of Sesame Street and educational children''s content',
    'https://www.sesameworkshop.org',
    true
),
(
    uuid_generate_v4(),
    'Khan Academy Kids',
    'khan-academy-kids',
    'Free, research-backed educational content for young learners',
    'https://www.khanacademy.org/kids',
    true
),
(
    uuid_generate_v4(),
    'BabyFirst',
    'baby-first',
    'Educational content specifically designed for babies and toddlers',
    'https://www.babyfirst.com',
    true
),
-- Music Creators
(
    uuid_generate_v4(),
    'Super Simple Songs',
    'super-simple-songs',
    'Original songs and nursery rhymes for children and teachers',
    'https://www.youtube.com/user/SuperSimpleSongs',
    true
),
(
    uuid_generate_v4(),
    'Cocomelon',
    'cocomelon',
    '3D animated videos of nursery rhymes and original children''s songs',
    'https://www.youtube.com/channel/UCbCmjCuTUZos6Inko4u57UQ',
    true
),
-- Story Creators
(
    uuid_generate_v4(),
    'Storyline Online',
    'storyline-online',
    'Famous actors reading children''s books aloud',
    'https://www.storylineonline.net',
    true
),
-- Independent Creators (for sample data)
(
    uuid_generate_v4(),
    'WonderNest Studios',
    'wondernest-studios',
    'In-house original content created specifically for the WonderNest platform',
    'https://wondernest.com/studios',
    true
);

-- =============================================================================
-- SAMPLE CONTENT ITEMS
-- =============================================================================

-- Get category IDs for content creation
WITH category_ids AS (
    SELECT 
        MAX(CASE WHEN slug = 'math-numbers' THEN id END) as math_id,
        MAX(CASE WHEN slug = 'letters-reading' THEN id END) as letters_id,
        MAX(CASE WHEN slug = 'science-nature' THEN id END) as science_id,
        MAX(CASE WHEN slug = 'social-skills' THEN id END) as social_id,
        MAX(CASE WHEN slug = 'adventure' THEN id END) as adventure_id,
        MAX(CASE WHEN slug = 'animals' THEN id END) as animals_id,
        MAX(CASE WHEN slug = 'music-songs' THEN id END) as music_id,
        MAX(CASE WHEN slug = 'stories-books' THEN id END) as stories_id
    FROM content.categories
),
creator_ids AS (
    SELECT 
        MAX(CASE WHEN slug = 'pbs-kids' THEN id END) as pbs_id,
        MAX(CASE WHEN slug = 'sesame-workshop' THEN id END) as sesame_id,
        MAX(CASE WHEN slug = 'khan-academy-kids' THEN id END) as khan_id,
        MAX(CASE WHEN slug = 'super-simple-songs' THEN id END) as songs_id,
        MAX(CASE WHEN slug = 'storyline-online' THEN id END) as stories_id,
        MAX(CASE WHEN slug = 'wondernest-studios' THEN id END) as wondernest_id
    FROM content.creators
)
INSERT INTO content.items (
    id, creator_id, title, description, content_type, language,
    primary_url, thumbnail_url, duration_seconds,
    min_age_months, max_age_months, educational_goals, learning_objectives,
    safety_score, educational_value_score, engagement_score,
    status, published_at, tags, keywords
)
SELECT * FROM (VALUES
-- Math & Numbers Content
(
    uuid_generate_v4(),
    (SELECT khan_id FROM creator_ids),
    'Counting to 10 with Animals',
    'Learn to count from 1 to 10 with friendly farm animals in this interactive video.',
    'video',
    'en',
    'https://content.wondernest.com/khan/counting-animals.mp4',
    'https://content.wondernest.com/khan/counting-animals-thumb.jpg',
    180, -- 3 minutes
    18, -- 18 months
    48, -- 4 years
    ARRAY['number_recognition', 'counting', 'animal_identification'],
    ARRAY['Count objects from 1 to 10', 'Recognize farm animals', 'Follow along with counting songs'],
    0.95,
    0.90,
    0.85,
    'approved',
    CURRENT_TIMESTAMP - INTERVAL '30 days',
    ARRAY['counting', 'numbers', 'animals', 'math', 'farm'],
    ARRAY['count', 'ten', 'animals', 'numbers', 'math']
),
(
    uuid_generate_v4(),
    (SELECT pbs_id FROM creator_ids),
    'Shapes All Around Us',
    'Discover circles, squares, triangles, and rectangles in everyday objects around the house.',
    'game',
    'en',
    'https://content.wondernest.com/pbs/shapes-game.html',
    'https://content.wondernest.com/pbs/shapes-thumb.jpg',
    300, -- 5 minutes
    24, -- 2 years
    60, -- 5 years
    ARRAY['shape_recognition', 'spatial_awareness', 'observation_skills'],
    ARRAY['Identify basic shapes', 'Find shapes in environment', 'Match shapes to objects'],
    0.98,
    0.88,
    0.82,
    'approved',
    CURRENT_TIMESTAMP - INTERVAL '25 days',
    ARRAY['shapes', 'geometry', 'matching', 'observation'],
    ARRAY['circle', 'square', 'triangle', 'rectangle', 'shapes']
),
-- Letters & Reading Content
(
    uuid_generate_v4(),
    (SELECT sesame_id FROM creator_ids),
    'Elmo''s ABC Adventure',
    'Join Elmo as he explores the alphabet through fun songs and interactive activities.',
    'video',
    'en',
    'https://content.wondernest.com/sesame/elmo-abc.mp4',
    'https://content.wondernest.com/sesame/elmo-abc-thumb.jpg',
    900, -- 15 minutes
    36, -- 3 years
    72, -- 6 years
    ARRAY['alphabet_recognition', 'phonics', 'letter_sounds'],
    ARRAY['Recognize all 26 letters', 'Associate letters with sounds', 'Sing alphabet song'],
    0.99,
    0.92,
    0.90,
    'approved',
    CURRENT_TIMESTAMP - INTERVAL '20 days',
    ARRAY['alphabet', 'letters', 'elmo', 'sesame', 'abc'],
    ARRAY['alphabet', 'letters', 'phonics', 'reading', 'elmo']
),
-- Music Content
(
    uuid_generate_v4(),
    (SELECT songs_id FROM creator_ids),
    'The Wheels on the Bus',
    'Sing along with this classic children''s song featuring colorful animations and sound effects.',
    'video',
    'en',
    'https://content.wondernest.com/songs/wheels-on-bus.mp4',
    'https://content.wondernest.com/songs/wheels-on-bus-thumb.jpg',
    240, -- 4 minutes
    12, -- 1 year
    48, -- 4 years
    ARRAY['music_appreciation', 'rhythm', 'vocabulary'],
    ARRAY['Sing familiar songs', 'Learn new vocabulary', 'Move to music'],
    0.96,
    0.75,
    0.88,
    'approved',
    CURRENT_TIMESTAMP - INTERVAL '15 days',
    ARRAY['music', 'song', 'bus', 'classic', 'nursery_rhyme'],
    ARRAY['wheels', 'bus', 'song', 'music', 'nursery']
),
-- Story Content
(
    uuid_generate_v4(),
    (SELECT stories_id FROM creator_ids),
    'The Very Hungry Caterpillar',
    'Listen to this beloved story about a caterpillar''s transformation into a beautiful butterfly.',
    'video',
    'en',
    'https://content.wondernest.com/stories/hungry-caterpillar.mp4',
    'https://content.wondernest.com/stories/hungry-caterpillar-thumb.jpg',
    600, -- 10 minutes
    24, -- 2 years
    72, -- 6 years
    ARRAY['story_comprehension', 'life_cycles', 'healthy_eating'],
    ARRAY['Follow story sequence', 'Learn about metamorphosis', 'Identify healthy foods'],
    0.97,
    0.85,
    0.92,
    'approved',
    CURRENT_TIMESTAMP - INTERVAL '10 days',
    ARRAY['story', 'caterpillar', 'butterfly', 'classic', 'book'],
    ARRAY['caterpillar', 'hungry', 'butterfly', 'story', 'book']
),
-- Science Content
(
    uuid_generate_v4(),
    (SELECT wondernest_id FROM creator_ids),
    'Weather and Seasons',
    'Explore different types of weather and learn about the four seasons through interactive activities.',
    'game',
    'en',
    'https://content.wondernest.com/wondernest/weather-seasons.html',
    'https://content.wondernest.com/wondernest/weather-thumb.jpg',
    450, -- 7.5 minutes
    36, -- 3 years
    84, -- 7 years
    ARRAY['weather_awareness', 'seasonal_changes', 'observation_skills'],
    ARRAY['Identify weather patterns', 'Understand seasons', 'Make weather predictions'],
    0.94,
    0.89,
    0.81,
    'approved',
    CURRENT_TIMESTAMP - INTERVAL '5 days',
    ARRAY['weather', 'seasons', 'science', 'nature', 'learning'],
    ARRAY['weather', 'rain', 'sun', 'snow', 'seasons']
),
-- Physical Activity Content
(
    uuid_generate_v4(),
    (SELECT wondernest_id FROM creator_ids),
    'Animal Yoga for Kids',
    'Practice yoga poses inspired by animals while learning about different creatures.',
    'video',
    'en',
    'https://content.wondernest.com/wondernest/animal-yoga.mp4',
    'https://content.wondernest.com/wondernest/animal-yoga-thumb.jpg',
    900, -- 15 minutes
    24, -- 2 years
    84, -- 7 years
    ARRAY['physical_development', 'body_awareness', 'animal_knowledge'],
    ARRAY['Practice basic yoga poses', 'Improve balance and flexibility', 'Learn animal facts'],
    0.93,
    0.82,
    0.86,
    'approved',
    CURRENT_TIMESTAMP - INTERVAL '3 days',
    ARRAY['yoga', 'exercise', 'animals', 'movement', 'health'],
    ARRAY['yoga', 'stretch', 'animals', 'exercise', 'movement']
)
) AS content_data;

-- =============================================================================
-- CONTENT CATEGORY MAPPINGS
-- =============================================================================

-- Link content to categories
WITH content_mappings AS (
    SELECT 
        ci.id as content_id,
        CASE 
            WHEN ci.title LIKE '%Counting%' OR ci.title LIKE '%Shapes%' THEN 
                (SELECT id FROM content.categories WHERE slug = 'math-numbers')
            WHEN ci.title LIKE '%ABC%' OR ci.title LIKE '%Elmo%' THEN 
                (SELECT id FROM content.categories WHERE slug = 'letters-reading')
            WHEN ci.title LIKE '%Bus%' OR ci.title LIKE '%Yoga%' THEN 
                (SELECT id FROM content.categories WHERE slug = 'music-songs')
            WHEN ci.title LIKE '%Caterpillar%' THEN 
                (SELECT id FROM content.categories WHERE slug = 'stories-books')
            WHEN ci.title LIKE '%Weather%' THEN 
                (SELECT id FROM content.categories WHERE slug = 'science-nature')
            WHEN ci.title LIKE '%Yoga%' THEN 
                (SELECT id FROM content.categories WHERE slug = 'physical-activity')
        END as category_id,
        true as is_primary
    FROM content.items ci
    WHERE ci.status = 'approved'
)
INSERT INTO content.item_categories (content_id, category_id, is_primary)
SELECT content_id, category_id, is_primary
FROM content_mappings
WHERE category_id IS NOT NULL;

-- =============================================================================
-- DEVELOPMENTAL MILESTONES TEMPLATES
-- =============================================================================

INSERT INTO analytics.milestones (
    id, child_id, milestone_type, milestone_name, description,
    typical_age_months_min, typical_age_months_max,
    achieved, evidence_source
) VALUES
-- Language Milestones (template - no specific child)
(uuid_generate_v4(), NULL, 'language', 'First Words', 'Says first meaningful words like "mama" or "dada"', 8, 18, false, 'app_data'),
(uuid_generate_v4(), NULL, 'language', 'Two-Word Phrases', 'Combines two words to make simple phrases', 18, 24, false, 'app_data'),
(uuid_generate_v4(), NULL, 'language', '50-Word Vocabulary', 'Uses approximately 50 different words', 20, 30, false, 'app_data'),
(uuid_generate_v4(), NULL, 'language', 'Simple Sentences', 'Forms simple 3-4 word sentences', 24, 36, false, 'app_data'),
(uuid_generate_v4(), NULL, 'language', 'Question Words', 'Uses question words like "what", "where", "why"', 30, 42, false, 'app_data'),

-- Cognitive Milestones
(uuid_generate_v4(), NULL, 'cognitive', 'Object Permanence', 'Understands that objects exist even when not visible', 8, 12, false, 'app_data'),
(uuid_generate_v4(), NULL, 'cognitive', 'Cause and Effect', 'Understands that actions have consequences', 12, 18, false, 'app_data'),
(uuid_generate_v4(), NULL, 'cognitive', 'Symbolic Play', 'Uses objects to represent other things in play', 18, 30, false, 'app_data'),
(uuid_generate_v4(), NULL, 'cognitive', 'Counting to 5', 'Can count objects from 1 to 5', 36, 48, false, 'app_data'),
(uuid_generate_v4(), NULL, 'cognitive', 'Color Recognition', 'Identifies basic colors', 36, 54, false, 'app_data'),

-- Social-Emotional Milestones
(uuid_generate_v4(), NULL, 'social', 'Social Smiling', 'Smiles in response to others', 2, 4, false, 'parent_report'),
(uuid_generate_v4(), NULL, 'social', 'Stranger Anxiety', 'Shows preference for familiar people', 6, 12, false, 'parent_report'),
(uuid_generate_v4(), NULL, 'social', 'Parallel Play', 'Plays alongside other children', 18, 30, false, 'parent_report'),
(uuid_generate_v4(), NULL, 'social', 'Sharing', 'Begins to share toys with others', 30, 48, false, 'parent_report'),
(uuid_generate_v4(), NULL, 'social', 'Empathy', 'Shows concern for others'' feelings', 36, 60, false, 'parent_report');

-- =============================================================================
-- DATA RETENTION POLICIES
-- =============================================================================

INSERT INTO audit.data_retention_policies (
    table_name, retention_period_days, retention_criteria, description, legal_basis
) VALUES
-- User and family data
('core.users', 2555, '{}', 'User accounts retained for 7 years after deletion for compliance', 'Business requirement'),
('family.child_profiles', 2555, '{}', 'Child profiles retained for 7 years after archival for development research', 'COPPA compliance'),
('core.user_sessions', 30, '{}', 'User sessions retained for 30 days for security analysis', 'Security requirement'),
('core.password_reset_tokens', 7, '{}', 'Password reset tokens retained for 7 days', 'Security requirement'),

-- Content and engagement data
('content.engagement', 1825, '{}', 'Content engagement retained for 5 years for analytics', 'Business requirement'),
('audio.sessions', 1095, '{}', 'Audio session metadata retained for 3 years', 'Research and development'),
('audio.speech_metrics', 1095, '{}', 'Speech metrics retained for 3 years for development tracking', 'Research and development'),

-- Analytics and insights
('analytics.daily_child_metrics', 1825, '{}', 'Daily metrics retained for 5 years for longitudinal studies', 'Research and development'),
('analytics.events', 1095, '{}', 'Usage events retained for 3 years for analytics', 'Business requirement'),

-- Financial and subscription data
('subscription.transactions', 3650, '{}', 'Financial transactions retained for 10 years', 'Tax and regulatory compliance'),
('subscription.user_subscriptions', 2555, '{}', 'Subscription history retained for 7 years', 'Business requirement'),

-- Audit and compliance
('audit.activity_log', 2555, '{}', 'Audit logs retained for 7 years unless legal hold', 'Compliance requirement'),
('safety.content_reviews', 1825, '{}', 'Content safety reviews retained for 5 years', 'Safety compliance');

-- =============================================================================
-- SAMPLE ADMIN USER (for development/testing only)
-- =============================================================================

-- Create admin user (only for development - remove in production)
DO $$
DECLARE
    v_admin_user_id UUID;
    v_admin_family_id UUID;
BEGIN
    -- Create admin user
    v_admin_user_id := core.create_user(
        'admin@wondernest.internal',
        '$2a$12$dummy_hash_for_development_only', -- Replace with proper hash in production
        'System',
        'Administrator',
        'email',
        NULL,
        'UTC'
    );
    
    -- Set admin role and activate
    UPDATE core.users 
    SET 
        role = 'super_admin',
        status = 'active',
        email_verified = true,
        email_verified_at = CURRENT_TIMESTAMP
    WHERE id = v_admin_user_id;
    
    -- Create admin family for testing
    v_admin_family_id := family.create_family(
        v_admin_user_id,
        'Admin Test Family',
        'UTC'
    );
    
    RAISE NOTICE 'Created admin user with ID: %', v_admin_user_id;
    RAISE NOTICE 'Created admin family with ID: %', v_admin_family_id;
END $$;

-- =============================================================================
-- SAMPLE TEST DATA (for development only)
-- =============================================================================

-- Create sample families and children for testing
DO $$
DECLARE
    v_test_user_id UUID;
    v_test_family_id UUID;
    v_test_child_id UUID;
BEGIN
    -- Create test parent user
    v_test_user_id := core.create_user(
        'test.parent@example.com',
        '$2a$12$dummy_hash_for_development_only',
        'Test',
        'Parent',
        'email',
        NULL,
        'America/New_York'
    );
    
    -- Activate test user
    UPDATE core.users 
    SET status = 'active', email_verified = true, email_verified_at = CURRENT_TIMESTAMP
    WHERE id = v_test_user_id;
    
    -- Create test family
    v_test_family_id := family.create_family(
        v_test_user_id,
        'Test Family',
        'America/New_York'
    );
    
    -- Create test child
    v_test_child_id := family.create_child_profile(
        v_test_family_id,
        'Testchild',
        CURRENT_DATE - INTERVAL '3 years', -- 3 years old
        'not_specified',
        'en',
        ARRAY['animals', 'music', 'stories'],
        v_test_user_id
    );
    
    -- Create some sample engagement data
    INSERT INTO content.engagement (
        child_id, content_id, started_at, ended_at, 
        duration_seconds, completion_percentage, enjoyed_rating
    )
    SELECT 
        v_test_child_id,
        ci.id,
        CURRENT_TIMESTAMP - (random() * INTERVAL '30 days'),
        CURRENT_TIMESTAMP - (random() * INTERVAL '30 days') + (ci.duration_seconds || ' seconds')::INTERVAL,
        ci.duration_seconds + (random() * 60)::INTEGER - 30, -- Add some variation
        (random() * 100)::INTEGER,
        (random() * 5 + 1)::INTEGER
    FROM content.items ci
    WHERE ci.status = 'approved'
    AND ci.min_age_months <= 36 AND ci.max_age_months >= 36 -- 3 years old
    LIMIT 10;
    
    -- Calculate daily metrics for the test child
    PERFORM analytics.calculate_daily_metrics(v_test_child_id, CURRENT_DATE);
    PERFORM analytics.calculate_daily_metrics(v_test_child_id, CURRENT_DATE - 1);
    PERFORM analytics.calculate_daily_metrics(v_test_child_id, CURRENT_DATE - 2);
    
    RAISE NOTICE 'Created test user with ID: %', v_test_user_id;
    RAISE NOTICE 'Created test child with ID: %', v_test_child_id;
END $$;

-- =============================================================================
-- DATABASE STATISTICS UPDATE
-- =============================================================================

-- Update statistics for all tables after seed data insertion
ANALYZE core.users;
ANALYZE family.families;
ANALYZE family.child_profiles;
ANALYZE subscription.plans;
ANALYZE content.categories;
ANALYZE content.creators;
ANALYZE content.items;
ANALYZE content.item_categories;
ANALYZE analytics.milestones;
ANALYZE audit.data_retention_policies;

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Verify seed data was inserted correctly
SELECT 'Data verification:' AS check_type;

SELECT 'Subscription Plans:', COUNT(*) as count FROM subscription.plans;
SELECT 'Content Categories:', COUNT(*) as count FROM content.categories;
SELECT 'Content Creators:', COUNT(*) as count FROM content.creators;
SELECT 'Content Items:', COUNT(*) as count FROM content.items;
SELECT 'Milestone Templates:', COUNT(*) as count FROM analytics.milestones WHERE child_id IS NULL;
SELECT 'Data Retention Policies:', COUNT(*) as count FROM audit.data_retention_policies;
SELECT 'Test Users Created:', COUNT(*) as count FROM core.users WHERE email LIKE '%@example.com' OR email LIKE '%@wondernest.internal';

SELECT 'Seed data loaded successfully. Database is ready for development and testing.' AS result;