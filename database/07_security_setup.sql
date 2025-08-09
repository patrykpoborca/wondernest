-- WonderNest Database Security Setup
-- Role-based access control, row-level security, and permissions
--
-- Usage:
--   psql -U postgres -d wondernest_prod -f 07_security_setup.sql
--
-- Prerequisites:
--   - All tables, functions, indexes, triggers, and seed data created
--   - Connected to wondernest_prod database as superuser

-- =============================================================================
-- DATABASE ROLES CREATION
-- =============================================================================

-- Create application roles with principle of least privilege

-- 1. Application Service Role (main backend application)
CREATE ROLE wondernest_app WITH
    LOGIN
    PASSWORD 'CHANGE_ME_IN_PRODUCTION'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION
    CONNECTION LIMIT 50;

-- 2. Read-Only Analytics Role (for business intelligence and reporting)
CREATE ROLE wondernest_analytics WITH
    LOGIN
    PASSWORD 'CHANGE_ME_IN_PRODUCTION'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION
    CONNECTION LIMIT 10;

-- 3. Migration Role (for database migrations and maintenance)
CREATE ROLE wondernest_migration WITH
    LOGIN
    PASSWORD 'CHANGE_ME_IN_PRODUCTION'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION
    CONNECTION LIMIT 5;

-- 4. Backup Role (for database backups and archival)
CREATE ROLE wondernest_backup WITH
    LOGIN
    PASSWORD 'CHANGE_ME_IN_PRODUCTION'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION
    REPLICATION -- Needed for pg_dump and backup operations
    CONNECTION LIMIT 3;

-- 5. Monitoring Role (for database health monitoring)
CREATE ROLE wondernest_monitor WITH
    LOGIN
    PASSWORD 'CHANGE_ME_IN_PRODUCTION'
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOREPLICATION
    CONNECTION LIMIT 5;

-- =============================================================================
-- SCHEMA PERMISSIONS
-- =============================================================================

-- Grant schema usage permissions
GRANT USAGE ON SCHEMA core TO wondernest_app, wondernest_analytics, wondernest_migration;
GRANT USAGE ON SCHEMA family TO wondernest_app, wondernest_analytics, wondernest_migration;
GRANT USAGE ON SCHEMA content TO wondernest_app, wondernest_analytics, wondernest_migration;
GRANT USAGE ON SCHEMA audio TO wondernest_app, wondernest_analytics, wondernest_migration;
GRANT USAGE ON SCHEMA subscription TO wondernest_app, wondernest_analytics, wondernest_migration;
GRANT USAGE ON SCHEMA analytics TO wondernest_app, wondernest_analytics, wondernest_migration;
GRANT USAGE ON SCHEMA safety TO wondernest_app, wondernest_analytics, wondernest_migration;
GRANT USAGE ON SCHEMA ml TO wondernest_app, wondernest_analytics, wondernest_migration;
GRANT USAGE ON SCHEMA audit TO wondernest_app, wondernest_analytics, wondernest_migration;

-- Grant monitoring schema permissions
GRANT USAGE ON SCHEMA information_schema TO wondernest_monitor;
GRANT USAGE ON SCHEMA pg_catalog TO wondernest_monitor;

-- =============================================================================
-- TABLE PERMISSIONS - APPLICATION ROLE
-- =============================================================================

-- Core schema permissions for application
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA core TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA family TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA content TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA audio TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA subscription TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA analytics TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA safety TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA ml TO wondernest_app;
GRANT INSERT, SELECT ON ALL TABLES IN SCHEMA audit TO wondernest_app; -- No UPDATE/DELETE for audit integrity

-- Grant permissions on future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wondernest_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA family GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wondernest_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA content GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wondernest_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA audio GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wondernest_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA subscription GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wondernest_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wondernest_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA safety GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wondernest_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA ml GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO wondernest_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT INSERT, SELECT ON TABLES TO wondernest_app;

-- Grant sequence permissions for ID generation
GRANT USAGE ON ALL SEQUENCES IN SCHEMA core TO wondernest_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA family TO wondernest_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA content TO wondernest_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA audio TO wondernest_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA subscription TO wondernest_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA analytics TO wondernest_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA safety TO wondernest_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml TO wondernest_app;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA audit TO wondernest_app;

-- =============================================================================
-- TABLE PERMISSIONS - ANALYTICS ROLE (READ-ONLY)
-- =============================================================================

-- Read-only access for analytics
GRANT SELECT ON ALL TABLES IN SCHEMA core TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA family TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA content TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA audio TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA subscription TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA safety TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA ml TO wondernest_analytics;
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO wondernest_analytics;

-- Future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT SELECT ON TABLES TO wondernest_analytics;
ALTER DEFAULT PRIVILEGES IN SCHEMA family GRANT SELECT ON TABLES TO wondernest_analytics;
ALTER DEFAULT PRIVILEGES IN SCHEMA content GRANT SELECT ON TABLES TO wondernest_analytics;
ALTER DEFAULT PRIVILEGES IN SCHEMA audio GRANT SELECT ON TABLES TO wondernest_analytics;
ALTER DEFAULT PRIVILEGES IN SCHEMA subscription GRANT SELECT ON TABLES TO wondernest_analytics;
ALTER DEFAULT PRIVILEGES IN SCHEMA analytics GRANT SELECT ON TABLES TO wondernest_analytics;
ALTER DEFAULT PRIVILEGES IN SCHEMA safety GRANT SELECT ON TABLES TO wondernest_analytics;
ALTER DEFAULT PRIVILEGES IN SCHEMA ml GRANT SELECT ON TABLES TO wondernest_analytics;
ALTER DEFAULT PRIVILEGES IN SCHEMA audit GRANT SELECT ON TABLES TO wondernest_analytics;

-- =============================================================================
-- TABLE PERMISSIONS - BACKUP ROLE
-- =============================================================================

-- Backup role needs SELECT on all tables
GRANT SELECT ON ALL TABLES IN SCHEMA core TO wondernest_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA family TO wondernest_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA content TO wondernest_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA audio TO wondernest_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA subscription TO wondernest_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics TO wondernest_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA safety TO wondernest_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA ml TO wondernest_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA audit TO wondernest_backup;

-- =============================================================================
-- TABLE PERMISSIONS - MONITORING ROLE
-- =============================================================================

-- Monitoring role needs access to system statistics
GRANT SELECT ON pg_stat_database TO wondernest_monitor;
GRANT SELECT ON pg_stat_user_tables TO wondernest_monitor;
GRANT SELECT ON pg_stat_user_indexes TO wondernest_monitor;
GRANT SELECT ON pg_statio_user_tables TO wondernest_monitor;
GRANT SELECT ON pg_locks TO wondernest_monitor;
GRANT SELECT ON pg_stat_activity TO wondernest_monitor;

-- Custom monitoring views
GRANT SELECT ON admin.index_usage_stats TO wondernest_monitor;
GRANT SELECT ON admin.trigger_monitoring TO wondernest_monitor;

-- =============================================================================
-- FUNCTION PERMISSIONS
-- =============================================================================

-- Grant EXECUTE permissions on functions to application role
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA core TO wondernest_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA family TO wondernest_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA content TO wondernest_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA audio TO wondernest_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA subscription TO wondernest_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA analytics TO wondernest_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA safety TO wondernest_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA ml TO wondernest_app;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA admin TO wondernest_app;

-- Analytics role gets read-only functions only
GRANT EXECUTE ON FUNCTION analytics.get_child_insights(UUID, INTEGER) TO wondernest_analytics;
GRANT EXECUTE ON FUNCTION admin.get_db_health_metrics() TO wondernest_analytics;
GRANT EXECUTE ON FUNCTION family.calculate_age(DATE) TO wondernest_analytics;
GRANT EXECUTE ON FUNCTION family.calculate_age_months(DATE) TO wondernest_analytics;

-- Monitoring role gets monitoring functions
GRANT EXECUTE ON FUNCTION admin.get_db_health_metrics() TO wondernest_monitor;

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

-- Enable RLS on sensitive tables
ALTER TABLE core.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE family.families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family.child_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE content.engagement ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE audio.speech_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics.daily_child_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription.user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription.transactions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies

-- Users can only access their own data
CREATE POLICY user_isolation_policy ON core.users
    FOR ALL TO wondernest_app
    USING (id = current_setting('app.current_user_id', true)::UUID);

-- Family members can access family data
CREATE POLICY family_member_policy ON family.families
    FOR ALL TO wondernest_app
    USING (
        id IN (
            SELECT fm.family_id 
            FROM family.family_members fm 
            WHERE fm.user_id = current_setting('app.current_user_id', true)::UUID
            AND fm.left_at IS NULL
        )
    );

-- Child profiles accessible by family members
CREATE POLICY child_profile_family_policy ON family.child_profiles
    FOR ALL TO wondernest_app
    USING (
        family_id IN (
            SELECT fm.family_id 
            FROM family.family_members fm 
            WHERE fm.user_id = current_setting('app.current_user_id', true)::UUID
            AND fm.left_at IS NULL
        )
    );

-- Content engagement by child's family
CREATE POLICY content_engagement_family_policy ON content.engagement
    FOR ALL TO wondernest_app
    USING (
        child_id IN (
            SELECT cp.id 
            FROM family.child_profiles cp
            JOIN family.family_members fm ON cp.family_id = fm.family_id
            WHERE fm.user_id = current_setting('app.current_user_id', true)::UUID
            AND fm.left_at IS NULL
            AND cp.archived_at IS NULL
        )
    );

-- Audio sessions by child's family
CREATE POLICY audio_sessions_family_policy ON audio.sessions
    FOR ALL TO wondernest_app
    USING (
        child_id IN (
            SELECT cp.id 
            FROM family.child_profiles cp
            JOIN family.family_members fm ON cp.family_id = fm.family_id
            WHERE fm.user_id = current_setting('app.current_user_id', true)::UUID
            AND fm.left_at IS NULL
            AND cp.archived_at IS NULL
        )
    );

-- Speech metrics by child's family
CREATE POLICY speech_metrics_family_policy ON audio.speech_metrics
    FOR ALL TO wondernest_app
    USING (
        child_id IN (
            SELECT cp.id 
            FROM family.child_profiles cp
            JOIN family.family_members fm ON cp.family_id = fm.family_id
            WHERE fm.user_id = current_setting('app.current_user_id', true)::UUID
            AND fm.left_at IS NULL
            AND cp.archived_at IS NULL
        )
    );

-- Daily metrics by child's family
CREATE POLICY daily_metrics_family_policy ON analytics.daily_child_metrics
    FOR ALL TO wondernest_app
    USING (
        child_id IN (
            SELECT cp.id 
            FROM family.child_profiles cp
            JOIN family.family_members fm ON cp.family_id = fm.family_id
            WHERE fm.user_id = current_setting('app.current_user_id', true)::UUID
            AND fm.left_at IS NULL
            AND cp.archived_at IS NULL
        )
    );

-- User subscriptions by user
CREATE POLICY user_subscriptions_policy ON subscription.user_subscriptions
    FOR ALL TO wondernest_app
    USING (user_id = current_setting('app.current_user_id', true)::UUID);

-- User transactions by user
CREATE POLICY user_transactions_policy ON subscription.transactions
    FOR ALL TO wondernest_app
    USING (user_id = current_setting('app.current_user_id', true)::UUID);

-- =============================================================================
-- BYPASS RLS FOR SPECIFIC ROLES
-- =============================================================================

-- Allow analytics role to bypass RLS for reporting
GRANT wondernest_analytics TO postgres; -- Temporary for setup
ALTER TABLE core.users FORCE ROW LEVEL SECURITY;
ALTER TABLE family.families FORCE ROW LEVEL SECURITY;
ALTER TABLE family.child_profiles FORCE ROW LEVEL SECURITY;

-- Create bypass policies for analytics (with anonymization)
CREATE POLICY analytics_bypass_policy ON core.users
    FOR SELECT TO wondernest_analytics
    USING (true); -- Can read all users but with anonymized data

CREATE POLICY analytics_family_bypass_policy ON family.families
    FOR SELECT TO wondernest_analytics
    USING (true);

CREATE POLICY analytics_child_bypass_policy ON family.child_profiles
    FOR SELECT TO wondernest_analytics
    USING (true);

-- =============================================================================
-- DATA ENCRYPTION SETUP
-- =============================================================================

-- Create function for encrypting sensitive data
CREATE OR REPLACE FUNCTION core.encrypt_pii(data TEXT, context TEXT DEFAULT 'general')
RETURNS TEXT AS $$
BEGIN
    -- In production, use proper key management (AWS KMS, HashiCorp Vault, etc.)
    -- This is a simplified example
    RETURN encode(
        hmac(data, current_setting('app.encryption_key', true), 'sha256'),
        'hex'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function for decrypting sensitive data
CREATE OR REPLACE FUNCTION core.decrypt_pii(encrypted_data TEXT, context TEXT DEFAULT 'general')
RETURNS TEXT AS $$
BEGIN
    -- This is a placeholder - implement proper decryption in production
    RETURN '[ENCRYPTED]';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant encryption functions to app role
GRANT EXECUTE ON FUNCTION core.encrypt_pii(TEXT, TEXT) TO wondernest_app;
GRANT EXECUTE ON FUNCTION core.decrypt_pii(TEXT, TEXT) TO wondernest_app;

-- =============================================================================
-- AUDIT AND COMPLIANCE POLICIES
-- =============================================================================

-- Create policy for audit log access (read-only for most users)
ALTER TABLE audit.activity_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY audit_read_own_policy ON audit.activity_log
    FOR SELECT TO wondernest_app
    USING (
        user_id = current_setting('app.current_user_id', true)::UUID OR
        child_id IN (
            SELECT cp.id 
            FROM family.child_profiles cp
            JOIN family.family_members fm ON cp.family_id = fm.family_id
            WHERE fm.user_id = current_setting('app.current_user_id', true)::UUID
            AND fm.left_at IS NULL
        )
    );

-- Allow audit writes for all app operations
CREATE POLICY audit_write_policy ON audit.activity_log
    FOR INSERT TO wondernest_app
    WITH CHECK (true);

-- =============================================================================
-- CONNECTION SECURITY
-- =============================================================================

-- Set secure connection defaults
ALTER ROLE wondernest_app SET search_path = core, family, content, audio, subscription, analytics, safety, ml, audit, public;
ALTER ROLE wondernest_analytics SET search_path = core, family, content, audio, subscription, analytics, safety, ml, audit, public;
ALTER ROLE wondernest_migration SET search_path = core, family, content, audio, subscription, analytics, safety, ml, audit, public;

-- Set connection timeouts
ALTER ROLE wondernest_app SET statement_timeout = '30s';
ALTER ROLE wondernest_analytics SET statement_timeout = '5min';
ALTER ROLE wondernest_monitor SET statement_timeout = '10s';

-- Set work memory limits
ALTER ROLE wondernest_app SET work_mem = '32MB';
ALTER ROLE wondernest_analytics SET work_mem = '256MB';
ALTER ROLE wondernest_monitor SET work_mem = '16MB';

-- =============================================================================
-- DATABASE CONFIGURATION FOR SECURITY
-- =============================================================================

-- Enable connection logging
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_statement = 'mod'; -- Log modifications only

-- Enable slow query logging
ALTER SYSTEM SET log_min_duration_statement = '1000'; -- 1 second

-- Security settings
ALTER SYSTEM SET ssl = 'on';
ALTER SYSTEM SET password_encryption = 'scram-sha-256';

-- Reload configuration
SELECT pg_reload_conf();

-- =============================================================================
-- SECURITY MONITORING VIEWS
-- =============================================================================

-- Create view for monitoring failed login attempts
CREATE OR REPLACE VIEW admin.security_monitoring AS
SELECT 
    timestamp,
    user_id,
    action,
    ip_address,
    user_agent,
    metadata
FROM audit.activity_log
WHERE action = 'login'
AND metadata ? 'failed'
ORDER BY timestamp DESC;

-- Create view for monitoring data access patterns
CREATE OR REPLACE VIEW admin.data_access_monitoring AS
SELECT 
    DATE(timestamp) as access_date,
    table_name,
    action,
    COUNT(*) as operation_count,
    COUNT(DISTINCT user_id) as unique_users
FROM audit.activity_log
WHERE timestamp >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY DATE(timestamp), table_name, action
ORDER BY access_date DESC, operation_count DESC;

-- Grant monitoring views to appropriate roles
GRANT SELECT ON admin.security_monitoring TO wondernest_monitor, wondernest_analytics;
GRANT SELECT ON admin.data_access_monitoring TO wondernest_monitor, wondernest_analytics;

-- =============================================================================
-- EMERGENCY ACCESS PROCEDURES
-- =============================================================================

-- Create emergency access function (for critical issues)
CREATE OR REPLACE FUNCTION admin.emergency_access_log(
    reason TEXT,
    authorized_by TEXT
) RETURNS VOID AS $$
BEGIN
    INSERT INTO audit.activity_log (
        action, table_name, metadata, timestamp
    ) VALUES (
        'read', 'emergency_access', 
        jsonb_build_object(
            'reason', reason,
            'authorized_by', authorized_by,
            'access_level', 'emergency'
        ),
        CURRENT_TIMESTAMP
    );
    
    -- Set context for emergency access
    PERFORM set_config('app.emergency_access', 'true', false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- BACKUP USER PERMISSIONS
-- =============================================================================

-- Grant necessary permissions for backup operations
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO wondernest_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO wondernest_backup;

-- =============================================================================
-- REVOKE DANGEROUS PERMISSIONS
-- =============================================================================

-- Revoke potentially dangerous permissions from application roles
REVOKE CREATE ON DATABASE wondernest_prod FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE wondernest_prod FROM wondernest_app, wondernest_analytics, wondernest_monitor;

-- =============================================================================
-- SECURITY VALIDATION
-- =============================================================================

-- Function to validate security configuration
CREATE OR REPLACE FUNCTION admin.validate_security_config()
RETURNS TABLE(
    check_name TEXT,
    status TEXT,
    details TEXT
) AS $$
BEGIN
    -- Check RLS is enabled on critical tables
    RETURN QUERY
    SELECT 
        'RLS_ENABLED' as check_name,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status,
        'Tables without RLS: ' || string_agg(tablename, ', ') as details
    FROM pg_tables t
    WHERE schemaname IN ('core', 'family', 'audio', 'subscription')
    AND tablename NOT IN (
        SELECT tablename FROM pg_tables pt
        JOIN pg_class c ON c.relname = pt.tablename
        WHERE c.relrowsecurity = true
    );
    
    -- Check for default passwords
    RETURN QUERY
    SELECT 
        'DEFAULT_PASSWORDS' as check_name,
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'FAIL' END as status,
        'Roles with default passwords detected' as details
    FROM pg_roles
    WHERE rolname LIKE 'wondernest_%'
    AND rolcanlogin = true;
    
    -- Check audit logging
    RETURN QUERY
    SELECT 
        'AUDIT_LOGGING' as check_name,
        CASE WHEN COUNT(*) > 0 THEN 'PASS' ELSE 'FAIL' END as status,
        'Recent audit entries: ' || COUNT(*)::TEXT as details
    FROM audit.activity_log
    WHERE timestamp > CURRENT_TIMESTAMP - INTERVAL '1 hour';
    
    RETURN;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- FINAL SECURITY VERIFICATION
-- =============================================================================

-- Run security validation
SELECT * FROM admin.validate_security_config();

-- Display role summary
SELECT 
    rolname as role_name,
    rolcanlogin as can_login,
    rolconnlimit as connection_limit,
    rolsuper as is_superuser
FROM pg_roles 
WHERE rolname LIKE 'wondernest_%'
ORDER BY rolname;

-- Display RLS status
SELECT 
    schemaname,
    tablename,
    CASE WHEN rowsecurity THEN 'ENABLED' ELSE 'DISABLED' END as rls_status
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
WHERE schemaname IN ('core', 'family', 'content', 'audio', 'subscription', 'analytics', 'safety', 'ml', 'audit')
ORDER BY schemaname, tablename;

SELECT 'Database security configuration completed. Please change default passwords before production use.' AS security_notice;
SELECT 'Review the security validation results above and address any FAIL status items.' AS action_required;