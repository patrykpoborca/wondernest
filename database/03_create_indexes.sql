-- WonderNest Performance Indexes
-- Creates optimized indexes for common query patterns
--
-- Usage:
--   psql -U postgres -d wondernest_prod -f 03_create_indexes.sql
--
-- Prerequisites:
--   - Tables created (02_create_tables.sql)
--   - Connected to wondernest_prod database

-- =============================================================================
-- CORE SCHEMA INDEXES - User Management & Authentication
-- =============================================================================

-- Users table indexes
CREATE INDEX CONCURRENTLY idx_users_email_active ON core.users(email) WHERE status = 'active' AND deleted_at IS NULL;
CREATE INDEX CONCURRENTLY idx_users_external_auth ON core.users(external_id, auth_provider) WHERE external_id IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_users_status ON core.users(status) WHERE deleted_at IS NULL;
CREATE INDEX CONCURRENTLY idx_users_created_at ON core.users(created_at);
CREATE INDEX CONCURRENTLY idx_users_last_login ON core.users(last_login_at) WHERE last_login_at IS NOT NULL;
-- Full text search on user names
CREATE INDEX CONCURRENTLY idx_users_name_search ON core.users USING GIN(to_tsvector('english', first_name || ' ' || coalesce(last_name, '')));

-- User sessions indexes
CREATE INDEX CONCURRENTLY idx_user_sessions_token ON core.user_sessions(session_token) WHERE is_active = TRUE;
CREATE INDEX CONCURRENTLY idx_user_sessions_user_active ON core.user_sessions(user_id) WHERE is_active = TRUE;
CREATE INDEX CONCURRENTLY idx_user_sessions_expires ON core.user_sessions(expires_at) WHERE is_active = TRUE;
CREATE INDEX CONCURRENTLY idx_user_sessions_activity ON core.user_sessions(last_activity DESC) WHERE is_active = TRUE;
-- Cleanup expired sessions efficiently
CREATE INDEX CONCURRENTLY idx_user_sessions_expired ON core.user_sessions(expires_at) WHERE is_active = TRUE AND expires_at < CURRENT_TIMESTAMP;

-- Password reset tokens indexes
CREATE INDEX CONCURRENTLY idx_password_reset_user ON core.password_reset_tokens(user_id) WHERE used = FALSE;
CREATE INDEX CONCURRENTLY idx_password_reset_token ON core.password_reset_tokens(token) WHERE used = FALSE;
CREATE INDEX CONCURRENTLY idx_password_reset_expires ON core.password_reset_tokens(expires_at) WHERE used = FALSE;

-- =============================================================================
-- FAMILY SCHEMA INDEXES - Family Structure & Child Profiles
-- =============================================================================

-- Families indexes
CREATE INDEX CONCURRENTLY idx_families_created_by ON family.families(created_by);
CREATE INDEX CONCURRENTLY idx_families_name ON family.families(name);

-- Family members indexes
CREATE INDEX CONCURRENTLY idx_family_members_family ON family.family_members(family_id) WHERE left_at IS NULL;
CREATE INDEX CONCURRENTLY idx_family_members_user ON family.family_members(user_id) WHERE left_at IS NULL;
CREATE INDEX CONCURRENTLY idx_family_members_role ON family.family_members(family_id, role) WHERE left_at IS NULL;

-- Child profiles indexes - critical for most app operations
CREATE INDEX CONCURRENTLY idx_child_profiles_family ON family.child_profiles(family_id) WHERE archived_at IS NULL;
CREATE INDEX CONCURRENTLY idx_child_profiles_age ON family.child_profiles(family.calculate_age_months(birth_date)) WHERE archived_at IS NULL;
CREATE INDEX CONCURRENTLY idx_child_profiles_birth_date ON family.child_profiles(birth_date) WHERE archived_at IS NULL;
-- Age group categorization index
CREATE INDEX CONCURRENTLY idx_child_profiles_age_groups ON family.child_profiles(
    CASE 
        WHEN family.calculate_age_months(birth_date) < 12 THEN '0_12_months'
        WHEN family.calculate_age_months(birth_date) < 24 THEN '12_24_months'
        WHEN family.calculate_age_months(birth_date) < 36 THEN '2_3_years'
        WHEN family.calculate_age_months(birth_date) < 48 THEN '3_4_years'
        WHEN family.calculate_age_months(birth_date) < 60 THEN '4_5_years'
        WHEN family.calculate_age_months(birth_date) < 72 THEN '5_6_years'
        ELSE '6_8_years'
    END
) WHERE archived_at IS NULL;
-- Full text search on interests
CREATE INDEX CONCURRENTLY idx_child_profiles_interests ON family.child_profiles USING GIN(interests) WHERE archived_at IS NULL;

-- =============================================================================
-- SUBSCRIPTION SCHEMA INDEXES - Billing & Plans
-- =============================================================================

-- Subscription plans indexes
CREATE INDEX CONCURRENTLY idx_subscription_plans_type ON subscription.plans(type) WHERE is_active = TRUE;
CREATE INDEX CONCURRENTLY idx_subscription_plans_visible ON subscription.plans(is_visible, type) WHERE is_active = TRUE;

-- User subscriptions indexes
CREATE INDEX CONCURRENTLY idx_user_subscriptions_user ON subscription.user_subscriptions(user_id);
CREATE INDEX CONCURRENTLY idx_user_subscriptions_status ON subscription.user_subscriptions(status);
CREATE INDEX CONCURRENTLY idx_user_subscriptions_active ON subscription.user_subscriptions(user_id) WHERE status = 'active';
CREATE INDEX CONCURRENTLY idx_user_subscriptions_ending_soon ON subscription.user_subscriptions(current_period_ends_at) 
    WHERE status IN ('active', 'trial') AND current_period_ends_at < CURRENT_TIMESTAMP + INTERVAL '7 days';
-- Stripe integration indexes
CREATE INDEX CONCURRENTLY idx_user_subscriptions_stripe_id ON subscription.user_subscriptions(stripe_subscription_id) WHERE stripe_subscription_id IS NOT NULL;

-- Transaction indexes
CREATE INDEX CONCURRENTLY idx_transactions_user ON subscription.transactions(user_id, attempted_at DESC);
CREATE INDEX CONCURRENTLY idx_transactions_subscription ON subscription.transactions(subscription_id, attempted_at DESC) WHERE subscription_id IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_transactions_status_date ON subscription.transactions(status, attempted_at DESC);
CREATE INDEX CONCURRENTLY idx_transactions_stripe_intent ON subscription.transactions(stripe_payment_intent_id) WHERE stripe_payment_intent_id IS NOT NULL;

-- =============================================================================
-- CONTENT SCHEMA INDEXES - Content Library & Curation
-- =============================================================================

-- Content categories indexes
CREATE INDEX CONCURRENTLY idx_content_categories_parent ON content.categories(parent_id) WHERE is_active = TRUE;
CREATE INDEX CONCURRENTLY idx_content_categories_slug ON content.categories(slug) WHERE is_active = TRUE;
CREATE INDEX CONCURRENTLY idx_content_categories_sort ON content.categories(parent_id, sort_order) WHERE is_active = TRUE;

-- Content creators indexes
CREATE INDEX CONCURRENTLY idx_content_creators_slug ON content.creators(slug);
CREATE INDEX CONCURRENTLY idx_content_creators_verified ON content.creators(is_verified) WHERE is_verified = TRUE;

-- Content items indexes - most critical for app performance
CREATE INDEX CONCURRENTLY idx_content_items_status_published ON content.items(status, published_at DESC) WHERE archived_at IS NULL;
CREATE INDEX CONCURRENTLY idx_content_items_type_age ON content.items(content_type, min_age_months, max_age_months) WHERE status = 'approved' AND archived_at IS NULL;
CREATE INDEX CONCURRENTLY idx_content_items_creator ON content.items(creator_id, published_at DESC) WHERE status = 'approved' AND archived_at IS NULL;
CREATE INDEX CONCURRENTLY idx_content_items_safety_score ON content.items(safety_score DESC, published_at DESC) WHERE status = 'approved' AND archived_at IS NULL;
CREATE INDEX CONCURRENTLY idx_content_items_engagement ON content.items(engagement_score DESC, published_at DESC) WHERE status = 'approved' AND archived_at IS NULL;
-- Age-appropriate content lookup - critical query pattern
CREATE INDEX CONCURRENTLY idx_content_items_age_appropriate ON content.items(min_age_months, max_age_months, safety_score DESC, engagement_score DESC) 
    WHERE status = 'approved' AND archived_at IS NULL AND safety_score >= 0.8;
-- Full text search on content
CREATE INDEX CONCURRENTLY idx_content_items_fulltext ON content.items USING GIN(
    to_tsvector('english', title || ' ' || coalesce(description, '') || ' ' || array_to_string(tags, ' '))
) WHERE status = 'approved' AND archived_at IS NULL;
-- Content tags and keywords for filtering
CREATE INDEX CONCURRENTLY idx_content_items_tags ON content.items USING GIN(tags) WHERE status = 'approved' AND archived_at IS NULL;
CREATE INDEX CONCURRENTLY idx_content_items_keywords ON content.items USING GIN(keywords) WHERE status = 'approved' AND archived_at IS NULL;

-- Content category relationships indexes
CREATE INDEX CONCURRENTLY idx_item_categories_content ON content.item_categories(content_id);
CREATE INDEX CONCURRENTLY idx_item_categories_category ON content.item_categories(category_id);
CREATE INDEX CONCURRENTLY idx_item_categories_primary ON content.item_categories(category_id) WHERE is_primary = TRUE;

-- Content engagement indexes - for analytics and recommendations
-- Note: These are on partitioned tables, so indexes are created per partition
-- Main table index templates
CREATE INDEX CONCURRENTLY idx_content_engagement_child_date ON content.engagement(child_id, started_at DESC);
CREATE INDEX CONCURRENTLY idx_content_engagement_content_date ON content.engagement(content_id, started_at DESC);
CREATE INDEX CONCURRENTLY idx_content_engagement_completion ON content.engagement(child_id, completion_percentage DESC) WHERE completion_percentage > 0;
CREATE INDEX CONCURRENTLY idx_content_engagement_duration ON content.engagement(child_id, duration_seconds DESC) WHERE duration_seconds > 0;
-- For recommendation algorithms
CREATE INDEX CONCURRENTLY idx_content_engagement_liked ON content.engagement(child_id, content_id) WHERE enjoyed_rating >= 4;

-- =============================================================================
-- AUDIO SCHEMA INDEXES - Speech Analysis & Metrics
-- =============================================================================

-- Audio sessions indexes - partitioned table indexes
CREATE INDEX CONCURRENTLY idx_audio_sessions_child_date ON audio.sessions(child_id, started_at DESC);
CREATE INDEX CONCURRENTLY idx_audio_sessions_status ON audio.sessions(status, started_at DESC);
CREATE INDEX CONCURRENTLY idx_audio_sessions_processing ON audio.sessions(processing_started_at) WHERE status = 'processing';
-- Quality analysis
CREATE INDEX CONCURRENTLY idx_audio_sessions_quality ON audio.sessions(child_id, audio_quality_score DESC) WHERE audio_quality_score IS NOT NULL;

-- Speech metrics indexes - critical for dashboard analytics
CREATE INDEX CONCURRENTLY idx_speech_metrics_child_time ON audio.speech_metrics(child_id, start_time DESC);
CREATE INDEX CONCURRENTLY idx_speech_metrics_session ON audio.speech_metrics(session_id, start_time);
-- Aggregation queries
CREATE INDEX CONCURRENTLY idx_speech_metrics_daily_agg ON audio.speech_metrics(child_id, date_trunc('day', start_time));
CREATE INDEX CONCURRENTLY idx_speech_metrics_hourly_agg ON audio.speech_metrics(child_id, date_trunc('hour', start_time));
-- Word counting and vocabulary tracking
CREATE INDEX CONCURRENTLY idx_speech_metrics_words ON audio.speech_metrics(child_id, word_count DESC, unique_word_count DESC) WHERE word_count > 0;
CREATE INDEX CONCURRENTLY idx_speech_metrics_conversations ON audio.speech_metrics(child_id, conversation_turns DESC) WHERE conversation_turns > 0;

-- =============================================================================
-- ANALYTICS SCHEMA INDEXES - Insights & Reporting  
-- =============================================================================

-- Daily child metrics indexes - partitioned table
CREATE INDEX CONCURRENTLY idx_daily_child_metrics_child_date ON analytics.daily_child_metrics(child_id, date DESC);
CREATE INDEX CONCURRENTLY idx_daily_child_metrics_words ON analytics.daily_child_metrics(child_id, total_words DESC) WHERE total_words > 0;
CREATE INDEX CONCURRENTLY idx_daily_child_metrics_screen_time ON analytics.daily_child_metrics(child_id, total_screen_time_minutes DESC) WHERE total_screen_time_minutes > 0;
-- Weekly/monthly aggregations
CREATE INDEX CONCURRENTLY idx_daily_child_metrics_week ON analytics.daily_child_metrics(child_id, date_trunc('week', date));
CREATE INDEX CONCURRENTLY idx_daily_child_metrics_month ON analytics.daily_child_metrics(child_id, date_trunc('month', date));

-- Milestones indexes
CREATE INDEX CONCURRENTLY idx_milestones_child ON analytics.milestones(child_id, achieved, typical_age_months_min);
CREATE INDEX CONCURRENTLY idx_milestones_type ON analytics.milestones(milestone_type, typical_age_months_min);
CREATE INDEX CONCURRENTLY idx_milestones_achieved ON analytics.milestones(child_id, achieved_at DESC) WHERE achieved = TRUE;
CREATE INDEX CONCURRENTLY idx_milestones_pending ON analytics.milestones(child_id, typical_age_months_min) WHERE achieved = FALSE;

-- Events indexes - partitioned table for analytics
CREATE INDEX CONCURRENTLY idx_analytics_events_user_time ON analytics.events(user_id, timestamp DESC) WHERE user_id IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_analytics_events_child_time ON analytics.events(child_id, timestamp DESC) WHERE child_id IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_analytics_events_type ON analytics.events(event_type, timestamp DESC);
CREATE INDEX CONCURRENTLY idx_analytics_events_session ON analytics.events(session_id, timestamp) WHERE session_id IS NOT NULL;
-- For funnel analysis
CREATE INDEX CONCURRENTLY idx_analytics_events_funnel ON analytics.events(user_id, event_type, timestamp) WHERE user_id IS NOT NULL;

-- =============================================================================
-- ML SCHEMA INDEXES - Machine Learning & Recommendations
-- =============================================================================

-- Recommendation models indexes
CREATE INDEX CONCURRENTLY idx_recommendation_models_active ON ml.recommendation_models(is_active, deployed_at DESC) WHERE is_active = TRUE;
CREATE INDEX CONCURRENTLY idx_recommendation_models_type ON ml.recommendation_models(model_type, version);

-- Content recommendations indexes
CREATE INDEX CONCURRENTLY idx_content_recommendations_child ON ml.content_recommendations(child_id, score DESC) WHERE expires_at > CURRENT_TIMESTAMP;
CREATE INDEX CONCURRENTLY idx_content_recommendations_content ON ml.content_recommendations(content_id, score DESC) WHERE expires_at > CURRENT_TIMESTAMP;
CREATE INDEX CONCURRENTLY idx_content_recommendations_fresh ON ml.content_recommendations(child_id, generated_at DESC) 
    WHERE expires_at > CURRENT_TIMESTAMP AND shown_to_user = FALSE;
-- Model performance tracking
CREATE INDEX CONCURRENTLY idx_content_recommendations_feedback ON ml.content_recommendations(model_id, user_action, user_action_at) WHERE user_action IS NOT NULL;

-- =============================================================================
-- SAFETY SCHEMA INDEXES - Content Safety & Parental Controls
-- =============================================================================

-- Content reviews indexes
CREATE INDEX CONCURRENTLY idx_content_reviews_content ON safety.content_reviews(content_id, reviewed_at DESC);
CREATE INDEX CONCURRENTLY idx_content_reviews_reviewer ON safety.content_reviews(reviewed_by, reviewed_at DESC) WHERE reviewed_by IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_content_reviews_safety_rating ON safety.content_reviews(safety_rating, reviewed_at DESC);
-- AI vs human review analysis
CREATE INDEX CONCURRENTLY idx_content_reviews_source ON safety.content_reviews(review_source, confidence_level, reviewed_at DESC);

-- Parental controls indexes
CREATE INDEX CONCURRENTLY idx_parental_controls_child ON safety.parental_controls(child_id);

-- =============================================================================
-- AUDIT SCHEMA INDEXES - Audit Logs & Compliance
-- =============================================================================

-- Activity log indexes - partitioned table
CREATE INDEX CONCURRENTLY idx_activity_log_user_time ON audit.activity_log(user_id, timestamp DESC) WHERE user_id IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_activity_log_child_time ON audit.activity_log(child_id, timestamp DESC) WHERE child_id IS NOT NULL;
CREATE INDEX CONCURRENTLY idx_activity_log_action ON audit.activity_log(action, table_name, timestamp DESC);
CREATE INDEX CONCURRENTLY idx_activity_log_record ON audit.activity_log(table_name, record_id, timestamp DESC) WHERE record_id IS NOT NULL;
-- Compliance and legal hold
CREATE INDEX CONCURRENTLY idx_activity_log_retention ON audit.activity_log(retention_until) WHERE retention_until IS NOT NULL AND legal_hold = FALSE;
CREATE INDEX CONCURRENTLY idx_activity_log_legal_hold ON audit.activity_log(legal_hold, timestamp) WHERE legal_hold = TRUE;

-- Data retention policies indexes
CREATE INDEX CONCURRENTLY idx_data_retention_policies_table ON audit.data_retention_policies(table_name) WHERE is_active = TRUE;

-- =============================================================================
-- COMPOSITE INDEXES FOR COMPLEX QUERIES
-- =============================================================================

-- Complex content discovery query
CREATE INDEX CONCURRENTLY idx_content_discovery ON content.items(
    status, 
    min_age_months, 
    max_age_months, 
    safety_score DESC, 
    engagement_score DESC, 
    published_at DESC
) WHERE status = 'approved' AND archived_at IS NULL;

-- Child development dashboard query
CREATE INDEX CONCURRENTLY idx_child_dashboard ON analytics.daily_child_metrics(
    child_id, 
    date DESC, 
    total_words DESC, 
    vocabulary_diversity_score DESC
);

-- Family activity overview
CREATE INDEX CONCURRENTLY idx_family_activity ON family.child_profiles(
    family_id,
    created_at DESC
) WHERE archived_at IS NULL;

-- Subscription management dashboard
CREATE INDEX CONCURRENTLY idx_subscription_management ON subscription.user_subscriptions(
    status,
    current_period_ends_at,
    plan_id
);

-- =============================================================================
-- PARTIAL INDEXES FOR DATA CLEANUP AND MAINTENANCE
-- =============================================================================

-- Find orphaned sessions to cleanup
CREATE INDEX CONCURRENTLY idx_cleanup_expired_sessions ON core.user_sessions(expires_at) 
    WHERE expires_at < CURRENT_TIMESTAMP - INTERVAL '30 days';

-- Find old audit logs for archival
CREATE INDEX CONCURRENTLY idx_cleanup_old_audit_logs ON audit.activity_log(timestamp) 
    WHERE timestamp < CURRENT_TIMESTAMP - INTERVAL '2 years' AND legal_hold = FALSE;

-- Find completed audio sessions to process
CREATE INDEX CONCURRENTLY idx_audio_processing_queue ON audio.sessions(processing_started_at, status) 
    WHERE status = 'completed' AND processing_completed_at IS NULL;

-- =============================================================================
-- PERFORMANCE MONITORING INDEXES
-- =============================================================================

-- Monitor slow queries
CREATE INDEX CONCURRENTLY idx_performance_monitor_daily_metrics ON analytics.daily_child_metrics(date, created_at) 
    WHERE created_at > date + INTERVAL '2 hours'; -- Late metric calculations

-- Monitor content engagement patterns
CREATE INDEX CONCURRENTLY idx_engagement_patterns ON content.engagement(
    date_trunc('hour', started_at),
    completion_percentage
) WHERE completion_percentage > 80; -- High engagement content

-- =============================================================================
-- STATISTICS UPDATE
-- =============================================================================

-- Update table statistics for query planner
ANALYZE core.users;
ANALYZE family.child_profiles;
ANALYZE content.items;
ANALYZE subscription.user_subscriptions;
ANALYZE analytics.daily_child_metrics;

-- =============================================================================
-- INDEX USAGE MONITORING SETUP
-- =============================================================================

-- Create a view to monitor index usage
CREATE OR REPLACE VIEW admin.index_usage_stats AS
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch,
    CASE 
        WHEN idx_scan = 0 THEN 'Never used'
        WHEN idx_scan < 100 THEN 'Low usage'
        WHEN idx_scan < 1000 THEN 'Medium usage'
        ELSE 'High usage'
    END as usage_level
FROM pg_stat_user_indexes 
WHERE schemaname IN ('core', 'family', 'content', 'subscription', 'analytics', 'audio', 'ml', 'safety', 'audit')
ORDER BY idx_scan DESC;

SELECT 'Performance indexes created successfully. Monitor usage with admin.index_usage_stats view.' AS result;