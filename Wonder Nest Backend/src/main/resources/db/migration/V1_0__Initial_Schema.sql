-- V1__Initial_Schema.sql
-- Initial WonderNest database schema migration
-- This migration creates the basic structure that will be managed by Flyway going forward

-- =============================================================================
-- NOTE: The initial database setup is handled by Docker initialization scripts
-- This migration serves as a baseline for future schema changes
-- =============================================================================

-- Create a version tracking table for application schema versions
CREATE TABLE IF NOT EXISTS core.schema_versions (
    version VARCHAR(20) PRIMARY KEY,
    description TEXT NOT NULL,
    applied_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    applied_by VARCHAR(100) DEFAULT CURRENT_USER
);

-- Insert the initial schema version
INSERT INTO core.schema_versions (version, description) VALUES 
('1.0.0', 'Initial WonderNest schema with all core tables and data');

-- Add a comment about the migration strategy
COMMENT ON TABLE core.schema_versions IS 'Tracks application schema versions separate from Flyway migration versions';