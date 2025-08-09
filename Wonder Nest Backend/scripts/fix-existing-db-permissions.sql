-- Fix Database Permissions Script
-- This script fixes the permission issue for existing WonderNest databases
-- where the wondernest_app user doesn't have CREATE privileges on schemas
--
-- Usage:
--   psql -d wondernest_db -f scripts/fix-existing-db-permissions.sql
--
-- This script should be run as the postgres superuser or database owner

\echo 'Fixing WonderNest database permissions...'

-- Check if wondernest_app user exists
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'wondernest_app') THEN
        RAISE EXCEPTION 'User wondernest_app does not exist. Please run the full initialization script first.';
    END IF;
END
$$;

-- Grant CREATE privileges on all schemas to wondernest_app
GRANT CREATE ON SCHEMA public TO wondernest_app;
GRANT CREATE ON SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit TO wondernest_app;

-- Ensure all existing privileges are still in place
GRANT USAGE ON SCHEMA public TO wondernest_app;
GRANT USAGE ON SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit TO wondernest_app;

-- Grant all privileges on all existing tables and sequences
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit TO wondernest_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit TO wondernest_app;

-- Update default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT ALL PRIVILEGES ON TABLES TO wondernest_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT ALL PRIVILEGES ON SEQUENCES TO wondernest_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit 
    GRANT ALL PRIVILEGES ON TABLES TO wondernest_app;

ALTER DEFAULT PRIVILEGES IN SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit 
    GRANT ALL PRIVILEGES ON SEQUENCES TO wondernest_app;

\echo 'Database permissions fixed successfully!'
\echo 'The wondernest_app user now has CREATE privileges on all schemas.'