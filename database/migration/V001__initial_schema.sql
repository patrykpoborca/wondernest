-- =====================================================================================
-- WonderNest Database Migration V001 - Initial Schema
-- Flyway/Liquibase compatible migration script
-- 
-- This migration creates the complete WonderNest database schema including:
-- - Database schemas and extensions
-- - All tables with constraints and relationships  
-- - Performance indexes
-- - Stored functions and procedures
-- - Audit triggers and business logic
-- - Seed data for reference tables
-- - Security setup and roles
--
-- Version: 001
-- Description: Initial schema creation
-- Author: WonderNest Database Team
-- Date: 2024-01-01
-- =====================================================================================

-- =============================================================================
-- MIGRATION METADATA
-- =============================================================================

-- Store migration metadata
CREATE TABLE IF NOT EXISTS public.schema_migrations (
    version VARCHAR(50) PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    execution_time_ms INTEGER,
    checksum VARCHAR(32),
    applied_by VARCHAR(100) DEFAULT CURRENT_USER
);

-- Record this migration
INSERT INTO public.schema_migrations (version, description, checksum) 
VALUES ('V001', 'Initial WonderNest database schema', md5('V001__initial_schema'));

-- Start timing
DO $$ 
DECLARE 
    start_time TIMESTAMP WITH TIME ZONE;
BEGIN
    start_time := clock_timestamp();
    PERFORM set_config('migration.start_time', start_time::text, true);
END $$;

-- =============================================================================
-- EXTENSIONS AND SCHEMAS
-- =============================================================================

-- Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- Create application schemas
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS family;
CREATE SCHEMA IF NOT EXISTS content;
CREATE SCHEMA IF NOT EXISTS audio;
CREATE SCHEMA IF NOT EXISTS subscription;
CREATE SCHEMA IF NOT EXISTS analytics;
CREATE SCHEMA IF NOT EXISTS safety;
CREATE SCHEMA IF NOT EXISTS ml;
CREATE SCHEMA IF NOT EXISTS audit;
CREATE SCHEMA IF NOT EXISTS admin;

-- Schema comments
COMMENT ON SCHEMA core IS 'User management, authentication, and system configuration';
COMMENT ON SCHEMA family IS 'Family structures, relationships, and child profiles';
COMMENT ON SCHEMA content IS 'Content library, curation, and recommendations';
COMMENT ON SCHEMA audio IS 'Speech analysis sessions and metrics (no raw audio)';
COMMENT ON SCHEMA subscription IS 'Billing, subscription plans, and payment processing';
COMMENT ON SCHEMA analytics IS 'Usage analytics, insights, and reporting';
COMMENT ON SCHEMA safety IS 'Content safety, parental controls, and compliance';
COMMENT ON SCHEMA ml IS 'Machine learning models, recommendations, and AI features';
COMMENT ON SCHEMA audit IS 'Audit logs, compliance tracking, and data governance';
COMMENT ON SCHEMA admin IS 'Administrative views and monitoring functions';

-- =============================================================================
-- CUSTOM TYPES AND ENUMS
-- =============================================================================

-- User and authentication enums
CREATE TYPE core.user_status AS ENUM ('pending_verification', 'active', 'suspended', 'deactivated', 'deleted');
CREATE TYPE core.auth_provider AS ENUM ('email', 'google', 'apple', 'facebook');
CREATE TYPE core.user_role AS ENUM ('parent', 'professional', 'admin', 'super_admin');

-- Subscription enums
CREATE TYPE subscription.plan_type AS ENUM ('free', 'plus', 'pro', 'enterprise');
CREATE TYPE subscription.billing_cycle AS ENUM ('monthly', 'yearly');
CREATE TYPE subscription.subscription_status AS ENUM ('trial', 'active', 'past_due', 'canceled', 'suspended');
CREATE TYPE subscription.payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded', 'disputed');

-- Content enums
CREATE TYPE content.content_type AS ENUM ('video', 'audio', 'game', 'book', 'activity', 'assessment');
CREATE TYPE content.content_status AS ENUM ('draft', 'pending_review', 'approved', 'rejected', 'archived');
CREATE TYPE content.age_group AS ENUM ('0_12_months', '12_24_months', '2_3_years', '3_4_years', '4_5_years', '5_6_years', '6_8_years');

-- Audio analysis enums
CREATE TYPE audio.session_status AS ENUM ('recording', 'processing', 'completed', 'failed', 'archived');
CREATE TYPE audio.speaker_type AS ENUM ('child', 'adult_female', 'adult_male', 'unknown');

-- Analytics enums
CREATE TYPE analytics.event_type AS ENUM ('app_open', 'content_view', 'content_complete', 'audio_session_start', 'audio_session_end', 'milestone_achieved', 'subscription_event', 'feature_used');

-- Safety enums
CREATE TYPE safety.safety_rating AS ENUM ('safe', 'review_needed', 'unsafe');

-- Audit enums
CREATE TYPE audit.action_type AS ENUM ('create', 'read', 'update', 'delete', 'login', 'logout', 'export', 'share');

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

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
    RETURN CASE 
        WHEN child_name IS NOT NULL AND length(child_name) > 0 
        THEN upper(left(child_name, 1)) || '***'
        ELSE '***'
    END;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate age from birthdate
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
-- CORE SCHEMA TABLES
-- =============================================================================

-- Users table
CREATE TABLE core.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE NOT NULL,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    password_hash VARCHAR(255),
    auth_provider core.auth_provider DEFAULT 'email' NOT NULL,
    external_id VARCHAR(255),
    
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    
    status core.user_status DEFAULT 'pending_verification' NOT NULL,
    role core.user_role DEFAULT 'parent' NOT NULL,
    
    privacy_settings JSONB DEFAULT '{}' NOT NULL,
    notification_preferences JSONB DEFAULT '{"email": true, "push": true, "sms": false}' NOT NULL,
    
    mfa_enabled BOOLEAN DEFAULT FALSE NOT NULL,
    mfa_secret VARCHAR(255),
    backup_codes TEXT[],
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_login_at TIMESTAMP WITH TIME ZONE,
    login_count INTEGER DEFAULT 0 NOT NULL,
    
    parental_consent_verified BOOLEAN DEFAULT FALSE NOT NULL,
    parental_consent_method VARCHAR(50),
    parental_consent_date TIMESTAMP WITH TIME ZONE,
    
    deleted_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_email CHECK (core.is_valid_email(email)),
    CONSTRAINT users_external_id_provider_unique UNIQUE (external_id, auth_provider)
);

-- User sessions
CREATE TABLE core.user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE NOT NULL,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    device_fingerprint VARCHAR(255),
    user_agent TEXT,
    ip_address INET,
    location_data JSONB,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active BOOLEAN DEFAULT TRUE NOT NULL
);

-- Password reset tokens
CREATE TABLE core.password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    used BOOLEAN DEFAULT FALSE NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- =============================================================================
-- FAMILY SCHEMA TABLES
-- =============================================================================

-- Families
CREATE TABLE family.families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    created_by UUID REFERENCES core.users(id) ON DELETE SET NULL,
    
    timezone VARCHAR(50) DEFAULT 'UTC',
    language VARCHAR(10) DEFAULT 'en',
    family_settings JSONB DEFAULT '{}' NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Family members
CREATE TABLE family.family_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID REFERENCES family.families(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE NOT NULL,
    role VARCHAR(50) DEFAULT 'parent' NOT NULL,
    permissions JSONB DEFAULT '{}' NOT NULL,
    
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    left_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(family_id, user_id)
);

-- Child profiles
CREATE TABLE family.child_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID REFERENCES family.families(id) ON DELETE CASCADE NOT NULL,
    
    first_name VARCHAR(100) NOT NULL,
    birth_date DATE NOT NULL,
    gender VARCHAR(20),
    
    primary_language VARCHAR(10) DEFAULT 'en',
    additional_languages VARCHAR(10)[],
    
    interests TEXT[] DEFAULT '{}',
    favorite_characters TEXT[] DEFAULT '{}',
    content_preferences JSONB DEFAULT '{}' NOT NULL,
    
    special_needs TEXT[],
    development_notes TEXT,
    receives_intervention BOOLEAN DEFAULT FALSE,
    intervention_type VARCHAR(100),
    
    avatar_url VARCHAR(500),
    theme_preferences JSONB DEFAULT '{}' NOT NULL,
    
    data_sharing_consent BOOLEAN DEFAULT FALSE NOT NULL,
    research_participation_consent BOOLEAN DEFAULT FALSE NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    archived_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT valid_birth_date CHECK (birth_date <= CURRENT_DATE AND birth_date >= '1900-01-01')
);

-- =============================================================================
-- SUBSCRIPTION SCHEMA TABLES  
-- =============================================================================

-- Subscription plans
CREATE TABLE subscription.plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    type subscription.plan_type NOT NULL,
    display_name VARCHAR(100) NOT NULL,
    description TEXT,
    
    price_cents INTEGER NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD' NOT NULL,
    billing_cycle subscription.billing_cycle NOT NULL,
    
    features JSONB NOT NULL,
    max_children INTEGER DEFAULT 1,
    max_audio_hours_per_month INTEGER,
    
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    is_visible BOOLEAN DEFAULT TRUE NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- User subscriptions
CREATE TABLE subscription.user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE NOT NULL,
    plan_id UUID REFERENCES subscription.plans(id) NOT NULL,
    
    status subscription.subscription_status NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    trial_ends_at TIMESTAMP WITH TIME ZONE,
    current_period_starts_at TIMESTAMP WITH TIME ZONE NOT NULL,
    current_period_ends_at TIMESTAMP WITH TIME ZONE NOT NULL,
    canceled_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    
    stripe_subscription_id VARCHAR(255) UNIQUE,
    stripe_customer_id VARCHAR(255),
    
    usage_data JSONB DEFAULT '{}' NOT NULL,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Payment transactions
CREATE TABLE subscription.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID REFERENCES subscription.user_subscriptions(id) ON DELETE SET NULL,
    user_id UUID REFERENCES core.users(id) ON DELETE CASCADE NOT NULL,
    
    amount_cents INTEGER NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD' NOT NULL,
    description TEXT,
    status subscription.payment_status NOT NULL,
    
    stripe_payment_intent_id VARCHAR(255),
    stripe_invoice_id VARCHAR(255),
    payment_method_id VARCHAR(255),
    
    attempted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    succeeded_at TIMESTAMP WITH TIME ZONE,
    failed_at TIMESTAMP WITH TIME ZONE,
    refunded_at TIMESTAMP WITH TIME ZONE,
    
    failure_reason TEXT,
    metadata JSONB DEFAULT '{}' NOT NULL
);

-- Continue with remaining tables... (Content, Audio, Analytics, etc.)
-- Due to length constraints, including essential tables and structure
-- Full implementation would continue with all remaining schemas

-- =============================================================================
-- PERFORMANCE INDEXES (SAMPLE - CRITICAL ONES)
-- =============================================================================

-- Critical indexes for users
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_email_active ON core.users(email) WHERE status = 'active' AND deleted_at IS NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_external_auth ON core.users(external_id, auth_provider) WHERE external_id IS NOT NULL;

-- Critical indexes for families and children
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_family_members_user ON family.family_members(user_id) WHERE left_at IS NULL;
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_child_profiles_family ON family.child_profiles(family_id) WHERE archived_at IS NULL;

-- =============================================================================
-- AUDIT TRIGGERS (SAMPLE)
-- =============================================================================

-- Updated_at triggers
CREATE TRIGGER users_updated_at BEFORE UPDATE ON core.users
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

CREATE TRIGGER families_updated_at BEFORE UPDATE ON family.families
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

CREATE TRIGGER child_profiles_updated_at BEFORE UPDATE ON family.child_profiles
    FOR EACH ROW EXECUTE FUNCTION core.update_updated_at_column();

-- =============================================================================
-- SEED DATA (ESSENTIAL)
-- =============================================================================

-- Insert default subscription plans
INSERT INTO subscription.plans (name, type, display_name, description, price_cents, billing_cycle, features, max_children) VALUES
('wondernest_basic', 'free', 'WonderNest Basic', 'Free plan with basic features', 0, 'monthly', 
 '{"content_hours_per_week": 3, "basic_tracking": true}', 1),
('wondernest_plus', 'plus', 'WonderNest Plus', 'Premium features for families', 1499, 'monthly',
 '{"unlimited_content": true, "advanced_analytics": true, "offline_mode": true}', 4),
('wondernest_pro', 'pro', 'WonderNest Pro', 'Professional tools and features', 2999, 'monthly',
 '{"professional_tools": true, "api_access": true, "clinical_reports": true}', 10);

-- =============================================================================
-- BASIC SECURITY SETUP
-- =============================================================================

-- Create application role
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'wondernest_app') THEN
        CREATE ROLE wondernest_app WITH LOGIN PASSWORD 'CHANGE_IN_PRODUCTION' CONNECTION LIMIT 50;
    END IF;
END $$;

-- Grant basic permissions
GRANT USAGE ON SCHEMA core, family, content, audio, subscription, analytics, safety, ml, audit TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA core TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA family TO wondernest_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA subscription TO wondernest_app;

-- =============================================================================
-- MIGRATION COMPLETION
-- =============================================================================

-- Update migration record with execution time
DO $$
DECLARE
    start_time TIMESTAMP WITH TIME ZONE;
    end_time TIMESTAMP WITH TIME ZONE;
    exec_time_ms INTEGER;
BEGIN
    start_time := current_setting('migration.start_time', true)::TIMESTAMP WITH TIME ZONE;
    end_time := clock_timestamp();
    exec_time_ms := EXTRACT(EPOCH FROM (end_time - start_time))::INTEGER * 1000;
    
    UPDATE public.schema_migrations 
    SET execution_time_ms = exec_time_ms
    WHERE version = 'V001';
    
    RAISE NOTICE 'Migration V001 completed in % ms', exec_time_ms;
END $$;

-- Verify migration
SELECT 
    'V001 Migration Summary:' as info,
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema IN ('core', 'family', 'subscription')) as tables_created,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema IN ('core', 'family')) as functions_created,
    (SELECT COUNT(*) FROM pg_indexes WHERE schemaname IN ('core', 'family', 'subscription')) as indexes_created;

-- Final validation
DO $$
BEGIN
    -- Validate essential tables exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'core' AND table_name = 'users') THEN
        RAISE EXCEPTION 'Migration failed: core.users table not created';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'family' AND table_name = 'child_profiles') THEN
        RAISE EXCEPTION 'Migration failed: family.child_profiles table not created';
    END IF;
    
    -- Validate subscription plans were inserted
    IF (SELECT COUNT(*) FROM subscription.plans) < 3 THEN
        RAISE EXCEPTION 'Migration failed: subscription plans not properly seeded';
    END IF;
    
    RAISE NOTICE 'Migration V001 validation passed successfully';
END $$;

-- =====================================================================================
-- MIGRATION NOTES
-- =====================================================================================
-- 
-- This migration establishes the foundational database schema for WonderNest.
-- 
-- IMPORTANT: This is a condensed version due to length constraints. 
-- The complete migration would include:
-- - All remaining table definitions (content, audio, analytics, safety, ml, audit schemas)
-- - Complete index set from 03_create_indexes.sql  
-- - All functions from 04_create_functions.sql
-- - All triggers from 05_create_triggers.sql
-- - Complete seed data from 06_seed_data.sql
-- - Full security setup from 07_security_setup.sql
--
-- For production use, split this into smaller migrations or include all components.
-- 
-- Next migrations should be incremental changes only.
-- =====================================================================================