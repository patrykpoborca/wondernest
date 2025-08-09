-- WonderNest Database Creation Script
-- Creates the main database and schemas for the child development platform
-- 
-- Usage:
--   psql -U postgres -f 01_create_database.sql
--
-- Prerequisites:
--   - PostgreSQL 15+
--   - Superuser privileges

-- =============================================================================
-- DATABASE CREATION
-- =============================================================================

-- Create the main WonderNest database
-- Note: This must be run as a separate command if not connected as superuser
-- CREATE DATABASE wondernest_prod WITH
--     ENCODING = 'UTF8'
--     LC_COLLATE = 'en_US.UTF-8'
--     LC_CTYPE = 'en_US.UTF-8'
--     TEMPLATE = template0;

-- Connect to the WonderNest database
\c wondernest_prod;

-- =============================================================================
-- EXTENSIONS
-- =============================================================================

-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";           -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";            -- Cryptographic functions
CREATE EXTENSION IF NOT EXISTS "pg_trgm";             -- Text similarity search
CREATE EXTENSION IF NOT EXISTS "btree_gin";           -- GIN indexes for btree types
CREATE EXTENSION IF NOT EXISTS "btree_gist";          -- GIST indexes for btree types
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";  -- Query statistics

-- =============================================================================
-- SCHEMAS
-- =============================================================================

-- Create application schemas for logical separation
CREATE SCHEMA IF NOT EXISTS core
    COMMENT ON SCHEMA core IS 'Core user management, authentication, and system configuration';

CREATE SCHEMA IF NOT EXISTS family  
    COMMENT ON SCHEMA family IS 'Family structures, relationships, and child profiles';

CREATE SCHEMA IF NOT EXISTS content
    COMMENT ON SCHEMA content IS 'Content library, curation, and recommendations';

CREATE SCHEMA IF NOT EXISTS audio
    COMMENT ON SCHEMA audio IS 'Speech analysis sessions and metrics (no raw audio)';

CREATE SCHEMA IF NOT EXISTS subscription
    COMMENT ON SCHEMA subscription IS 'Billing, subscription plans, and payment processing';

CREATE SCHEMA IF NOT EXISTS analytics
    COMMENT ON SCHEMA analytics IS 'Usage analytics, insights, and reporting';

CREATE SCHEMA IF NOT EXISTS safety
    COMMENT ON SCHEMA safety IS 'Content safety, parental controls, and compliance';

CREATE SCHEMA IF NOT EXISTS ml
    COMMENT ON SCHEMA ml IS 'Machine learning models, recommendations, and AI features';

CREATE SCHEMA IF NOT EXISTS audit
    COMMENT ON SCHEMA audit IS 'Audit logs, compliance tracking, and data governance';

-- =============================================================================
-- CUSTOM TYPES & ENUMS
-- =============================================================================

-- User and authentication related enums
CREATE TYPE core.user_status AS ENUM (
    'pending_verification',
    'active', 
    'suspended',
    'deactivated',
    'deleted'
);

CREATE TYPE core.auth_provider AS ENUM (
    'email',
    'google',
    'apple',
    'facebook'
);

CREATE TYPE core.user_role AS ENUM (
    'parent',
    'professional', 
    'admin',
    'super_admin'
);

-- Subscription related enums
CREATE TYPE subscription.plan_type AS ENUM (
    'free',
    'plus',
    'pro',
    'enterprise'
);

CREATE TYPE subscription.billing_cycle AS ENUM (
    'monthly',
    'yearly'
);

CREATE TYPE subscription.subscription_status AS ENUM (
    'trial',
    'active',
    'past_due',
    'canceled',
    'suspended'
);

CREATE TYPE subscription.payment_status AS ENUM (
    'pending',
    'completed',
    'failed',
    'refunded',
    'disputed'
);

-- Content related enums  
CREATE TYPE content.content_type AS ENUM (
    'video',
    'audio',
    'game',
    'book',
    'activity',
    'assessment'
);

CREATE TYPE content.content_status AS ENUM (
    'draft',
    'pending_review',
    'approved',
    'rejected',
    'archived'
);

CREATE TYPE content.age_group AS ENUM (
    '0_12_months',
    '12_24_months', 
    '2_3_years',
    '3_4_years',
    '4_5_years',
    '5_6_years',
    '6_8_years'
);

-- Audio analysis enums
CREATE TYPE audio.session_status AS ENUM (
    'recording',
    'processing', 
    'completed',
    'failed',
    'archived'
);

CREATE TYPE audio.speaker_type AS ENUM (
    'child',
    'adult_female',
    'adult_male',
    'unknown'
);

-- Analytics enums
CREATE TYPE analytics.event_type AS ENUM (
    'app_open',
    'content_view',
    'content_complete',
    'audio_session_start',
    'audio_session_end',
    'milestone_achieved',
    'subscription_event',
    'feature_used'
);

-- Safety and compliance enums
CREATE TYPE safety.safety_rating AS ENUM (
    'safe',
    'review_needed',
    'unsafe'
);

CREATE TYPE audit.action_type AS ENUM (
    'create',
    'read', 
    'update',
    'delete',
    'login',
    'logout',
    'export',
    'share'
);

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

-- Function to generate short, URL-safe IDs
CREATE OR REPLACE FUNCTION core.generate_short_id(length INTEGER DEFAULT 12)
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    result TEXT := '';
    i INTEGER := 0;
BEGIN
    FOR i IN 1..length LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION core.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to anonymize child data
CREATE OR REPLACE FUNCTION family.anonymize_child_name(child_name TEXT)
RETURNS TEXT AS $$
BEGIN
    -- Return only first initial for privacy
    RETURN CASE 
        WHEN child_name IS NOT NULL AND length(child_name) > 0 
        THEN upper(left(child_name, 1)) || '***'
        ELSE '***'
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate age from birthdate
CREATE OR REPLACE FUNCTION family.calculate_age(birth_date DATE)
RETURNS INTEGER AS $$
BEGIN
    RETURN date_part('year', age(birth_date));
END;
$$ LANGUAGE plpgsql;

-- Function to calculate age in months
CREATE OR REPLACE FUNCTION family.calculate_age_months(birth_date DATE)
RETURNS INTEGER AS $$
BEGIN
    RETURN (date_part('year', age(birth_date)) * 12 + date_part('month', age(birth_date)))::INTEGER;
END;
$$ LANGUAGE plpgsql;

-- Function to validate email format
CREATE OR REPLACE FUNCTION core.is_valid_email(email_address TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN email_address ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$';
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- CONFIGURATION SETTINGS
-- =============================================================================

-- Set timezone for the database session
SET timezone = 'UTC';

-- Configure text search
CREATE TEXT SEARCH CONFIGURATION wondernest_english (COPY = english);

-- =============================================================================
-- COMMENTS
-- =============================================================================

COMMENT ON DATABASE wondernest_prod IS 'WonderNest child development platform database - Production';
COMMENT ON EXTENSION "uuid-ossp" IS 'Provides UUID generation functions';
COMMENT ON EXTENSION "pgcrypto" IS 'Cryptographic functions for password hashing and encryption';
COMMENT ON EXTENSION "pg_trgm" IS 'Trigram matching for text similarity searches';

-- =============================================================================
-- SECURITY SETUP PLACEHOLDER
-- =============================================================================
-- Note: User roles and permissions will be created in 07_security_setup.sql
-- This ensures proper separation of concerns and secure defaults

-- Create a comment to remind about security setup
SELECT 'Database and schemas created successfully. Remember to run 07_security_setup.sql for proper security configuration.' AS reminder;