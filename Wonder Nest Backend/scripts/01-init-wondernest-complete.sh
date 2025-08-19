#!/bin/bash
set -e

# WonderNest Database Complete Initialization Script
# This script runs as part of PostgreSQL Docker entrypoint to initialize the database
# with proper users, schemas, and data. It contains all logic internally to avoid
# file mounting issues on macOS.

echo "🚀 Starting WonderNest database initialization..."

# Create application database if it doesn't exist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create the application database if it doesn't exist
    SELECT 'CREATE DATABASE $WONDERNEST_DB_NAME' WHERE NOT EXISTS (
        SELECT FROM pg_database WHERE datname = '$WONDERNEST_DB_NAME'
    )\gexec
EOSQL

echo "✅ Database '$WONDERNEST_DB_NAME' created or already exists"

# Create application users with proper permissions
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$WONDERNEST_DB_NAME" <<-EOSQL
    -- Create application user for the KTOR backend
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$WONDERNEST_APP_USER') THEN
            CREATE ROLE $WONDERNEST_APP_USER WITH
                LOGIN
                PASSWORD '$WONDERNEST_APP_PASSWORD'
                NOSUPERUSER
                NOCREATEDB
                NOCREATEROLE
                NOREPLICATION
                CONNECTION LIMIT 50;
        END IF;
    END
    \$\$;

    -- Create analytics user for read-only access
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$WONDERNEST_ANALYTICS_USER') THEN
            CREATE ROLE $WONDERNEST_ANALYTICS_USER WITH
                LOGIN
                PASSWORD '$WONDERNEST_ANALYTICS_PASSWORD'
                NOSUPERUSER
                NOCREATEDB
                NOCREATEROLE
                NOREPLICATION
                CONNECTION LIMIT 10;
        END IF;
    END
    \$\$;

    COMMENT ON ROLE $WONDERNEST_APP_USER IS 'Application user for WonderNest backend services';
    COMMENT ON ROLE $WONDERNEST_ANALYTICS_USER IS 'Read-only user for analytics and reporting';
    
    -- Grant database-level CREATE permission to allow schema creation by Flyway
    GRANT CREATE ON DATABASE $WONDERNEST_DB_NAME TO $WONDERNEST_APP_USER;
EOSQL

echo "✅ Application users created with database CREATE permissions"

# Check if the database is already initialized by looking for the core schema
INITIALIZED=$(psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$WONDERNEST_DB_NAME" --tuples-only --no-align -c "SELECT EXISTS(SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'core');")

if [ "$INITIALIZED" = "t" ]; then
    echo "🔄 Database already initialized, skipping schema creation"
else
    echo "📊 Initializing database schema..."

    # Create database schema inline (self-contained)
    echo "  1️⃣ Creating database schemas..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$WONDERNEST_DB_NAME" <<-EOSQL
        -- Create schemas for WonderNest application
        CREATE SCHEMA IF NOT EXISTS core;
        CREATE SCHEMA IF NOT EXISTS family;
        CREATE SCHEMA IF NOT EXISTS subscription;
        CREATE SCHEMA IF NOT EXISTS content;
        CREATE SCHEMA IF NOT EXISTS audio;
        CREATE SCHEMA IF NOT EXISTS analytics;
        CREATE SCHEMA IF NOT EXISTS ml;
        CREATE SCHEMA IF NOT EXISTS safety;
        CREATE SCHEMA IF NOT EXISTS audit;

        COMMENT ON SCHEMA core IS 'Core application entities (users, auth, system config)';
        COMMENT ON SCHEMA family IS 'Family management and relationships';
        COMMENT ON SCHEMA subscription IS 'Subscription and billing management';
        COMMENT ON SCHEMA content IS 'Content management and metadata';
        COMMENT ON SCHEMA audio IS 'Audio processing and storage';
        COMMENT ON SCHEMA analytics IS 'Analytics and reporting data';
        COMMENT ON SCHEMA ml IS 'Machine learning models and predictions';
        COMMENT ON SCHEMA safety IS 'Safety monitoring and controls';
        COMMENT ON SCHEMA audit IS 'Audit logging and compliance';
EOSQL

    echo "  2️⃣ Creating core application tables..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$WONDERNEST_DB_NAME" <<-EOSQL
        -- Essential tables for basic application functionality
        SET search_path TO core, public;

        -- Users table (essential for authentication)
        CREATE TABLE IF NOT EXISTS users (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            email VARCHAR(255) UNIQUE NOT NULL,
            password_hash VARCHAR(255) NOT NULL,
            first_name VARCHAR(100),
            last_name VARCHAR(100),
            phone VARCHAR(20),
            email_verified BOOLEAN DEFAULT FALSE,
            is_active BOOLEAN DEFAULT TRUE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        -- Sessions table (for authentication)
        CREATE TABLE IF NOT EXISTS user_sessions (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            token_hash VARCHAR(255) NOT NULL,
            expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            last_accessed TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            device_info JSONB
        );

        -- Database version tracking
        CREATE TABLE IF NOT EXISTS database_info (
            key VARCHAR(50) PRIMARY KEY,
            value TEXT NOT NULL,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        -- Basic indexes for performance
        CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
        CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);
        CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON user_sessions(user_id);
        CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(token_hash);
        CREATE INDEX IF NOT EXISTS idx_user_sessions_expires ON user_sessions(expires_at);

        -- Insert version information
        INSERT INTO database_info (key, value) VALUES ('db_version', '1.0.0')
        ON CONFLICT (key) DO UPDATE SET 
            value = EXCLUDED.value,
            created_at = CURRENT_TIMESTAMP;
            
        INSERT INTO database_info (key, value) VALUES ('initialized_at', NOW()::TEXT)
        ON CONFLICT (key) DO UPDATE SET 
            value = EXCLUDED.value,
            created_at = CURRENT_TIMESTAMP;
EOSQL

    echo "  3️⃣ Creating additional application tables..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$WONDERNEST_DB_NAME" <<-EOSQL
        -- Family schema tables
        SET search_path TO family, public;
        
        CREATE TABLE IF NOT EXISTS families (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name VARCHAR(100) NOT NULL,
            created_by UUID NOT NULL REFERENCES core.users(id),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS family_members (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
            user_id UUID NOT NULL REFERENCES core.users(id),
            role VARCHAR(20) DEFAULT 'member',
            joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(family_id, user_id)
        );

        -- Content schema tables
        SET search_path TO content, public;
        
        CREATE TABLE IF NOT EXISTS stories (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            title VARCHAR(200) NOT NULL,
            description TEXT,
            content TEXT,
            created_by UUID NOT NULL REFERENCES core.users(id),
            family_id UUID REFERENCES family.families(id),
            is_public BOOLEAN DEFAULT FALSE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        -- Audit schema for logging
        SET search_path TO audit, public;
        
        CREATE TABLE IF NOT EXISTS activity_logs (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID REFERENCES core.users(id),
            action VARCHAR(50) NOT NULL,
            entity_type VARCHAR(50),
            entity_id UUID,
            details JSONB,
            ip_address INET,
            user_agent TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );

        -- Create basic indexes
        CREATE INDEX IF NOT EXISTS idx_families_created_by ON family.families(created_by);
        CREATE INDEX IF NOT EXISTS idx_family_members_family_id ON family.family_members(family_id);
        CREATE INDEX IF NOT EXISTS idx_family_members_user_id ON family.family_members(user_id);
        CREATE INDEX IF NOT EXISTS idx_stories_created_by ON content.stories(created_by);
        CREATE INDEX IF NOT EXISTS idx_stories_family_id ON content.stories(family_id);
        CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON audit.activity_logs(user_id);
        CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON audit.activity_logs(created_at);
EOSQL
fi

# Grant permissions to application users
echo "🔐 Setting up user permissions..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$WONDERNEST_DB_NAME" <<-EOSQL
    -- Grant usage on all schemas to app user (including public for Flyway)
    GRANT USAGE ON SCHEMA public TO $WONDERNEST_APP_USER;
    GRANT USAGE ON SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit TO $WONDERNEST_APP_USER;
    
    -- Grant CREATE privileges on all schemas (including public for Flyway)
    GRANT CREATE ON SCHEMA public TO $WONDERNEST_APP_USER;
    GRANT CREATE ON SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit TO $WONDERNEST_APP_USER;
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO $WONDERNEST_APP_USER;
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO $WONDERNEST_APP_USER;
    
    -- Grant all privileges on all tables in each schema to app user
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit TO $WONDERNEST_APP_USER;
    
    -- Grant all privileges on all sequences to app user
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit TO $WONDERNEST_APP_USER;
    
    -- Grant usage on schemas to analytics user (read-only)
    GRANT USAGE ON SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit TO $WONDERNEST_ANALYTICS_USER;
    
    -- Grant select on all tables to analytics user
    GRANT SELECT ON ALL TABLES IN SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit TO $WONDERNEST_ANALYTICS_USER;
    
    -- Set default privileges for future tables
    ALTER DEFAULT PRIVILEGES IN SCHEMA public 
        GRANT ALL PRIVILEGES ON TABLES TO $WONDERNEST_APP_USER;
    
    ALTER DEFAULT PRIVILEGES IN SCHEMA public 
        GRANT ALL PRIVILEGES ON SEQUENCES TO $WONDERNEST_APP_USER;
    
    ALTER DEFAULT PRIVILEGES IN SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit 
        GRANT ALL PRIVILEGES ON TABLES TO $WONDERNEST_APP_USER;
    
    ALTER DEFAULT PRIVILEGES IN SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit 
        GRANT ALL PRIVILEGES ON SEQUENCES TO $WONDERNEST_APP_USER;
    
    ALTER DEFAULT PRIVILEGES IN SCHEMA core, family, subscription, content, audio, analytics, ml, safety, audit 
        GRANT SELECT ON TABLES TO $WONDERNEST_ANALYTICS_USER;
EOSQL

echo "✅ User permissions configured"

# Create a marker to track initialization completion
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$WONDERNEST_DB_NAME" <<-EOSQL
    -- Create initialization marker (handle case where core schema doesn't exist yet)
    DO \$\$
    BEGIN
        -- Only create the table if core schema exists
        IF EXISTS (SELECT schema_name FROM information_schema.schemata WHERE schema_name = 'core') THEN
            CREATE TABLE IF NOT EXISTS core.database_info (
                key VARCHAR(50) PRIMARY KEY,
                value TEXT NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
            );
            
            INSERT INTO core.database_info (key, value) VALUES ('db_version', '1.0.0')
            ON CONFLICT (key) DO UPDATE SET 
                value = EXCLUDED.value,
                created_at = CURRENT_TIMESTAMP;
                
            INSERT INTO core.database_info (key, value) VALUES ('initialized_at', NOW()::TEXT)
            ON CONFLICT (key) DO UPDATE SET 
                value = EXCLUDED.value,
                created_at = CURRENT_TIMESTAMP;
        END IF;
    END
    \$\$;
EOSQL

echo "🎉 WonderNest database initialization completed successfully!"
echo "📋 Database: $WONDERNEST_DB_NAME"
echo "👤 App User: $WONDERNEST_APP_USER"
echo "📊 Analytics User: $WONDERNEST_ANALYTICS_USER"
echo "🔗 Connection URL: postgresql://$WONDERNEST_APP_USER@postgres:5432/$WONDERNEST_DB_NAME"