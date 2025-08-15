# Flyway Database Migration Guide

## Overview

This project uses Flyway for database schema versioning and migrations. Flyway is integrated both into the application runtime (automatic migrations on startup) and as Gradle tasks (manual migration management).

## How Flyway Works

Flyway treats your database schema as code by:

1. **Version Control**: Each migration has a version number (V1, V2, V3, etc.)
2. **Tracking**: Applied migrations are recorded in `flyway_schema_history` table
3. **Ordering**: Migrations are applied in version order, only once
4. **Validation**: Flyway validates that applied migrations haven't been modified
5. **Consistency**: Ensures all environments have the same schema version

### Migration States

- ✅ **Success**: Migration applied successfully
- ❌ **Failed**: Migration failed during execution
- ⏳ **Pending**: Migration exists but hasn't been applied yet
- 🔄 **Repeatable**: Special migrations that run every time their checksum changes

## Project Configuration

### Automatic Migrations (Runtime)

- **Development Mode**: Migrations are skipped by default (set `KTOR_ENV=production` to enable)
- **Production Mode**: Migrations run automatically on server startup
- **Implementation**: `MigrationService.kt` handles automatic migrations

### Manual Migrations (Gradle Tasks)

Available Gradle tasks for manual migration management:

```bash
# Core Flyway tasks
./gradlew flywayInfo              # Show migration status
./gradlew flywayMigrate          # Apply pending migrations
./gradlew flywayValidate         # Validate applied migrations
./gradlew flywayRepair           # Repair migration history
./gradlew flywayClean            # Drop all objects (dev only)
./gradlew flywayBaseline         # Set baseline for existing database

# Custom tasks (with verbose output)
./gradlew flywayStatus           # Alias for flywayInfo
./gradlew flywayMigrateVerbose   # Migration with detailed output
./gradlew flywayValidateVerbose  # Validation with detailed output
```

## Migration File Structure

### Location
```
src/main/resources/db/migration/
├── V1__Initial_Schema.sql
├── V2__Complete_Schema.sql
├── V3__Add_User_Preferences.sql
└── V4__Update_Content_Table.sql
```

### Naming Convention

Flyway uses strict naming conventions:

```
V{VERSION}__{DESCRIPTION}.sql
```

**Examples:**
- ✅ `V1__Initial_Schema.sql`
- ✅ `V2_1__Add_User_Table.sql`  
- ✅ `V3__Update_Content_Filters.sql`
- ❌ `V1_0__Initial_Schema.sql` (underscore not allowed after version)
- ❌ `V1-Initial-Schema.sql` (dashes not allowed)
- ❌ `initial_schema.sql` (missing version prefix)

### Version Numbering

- **Major versions**: V1, V2, V3, etc.
- **Minor versions**: V2_1, V2_2, V2_3, etc.
- **Semantic**: Use meaningful version numbers
- **Sequential**: Versions must be applied in order

## Migration Workflow

### 1. Creating a New Migration

```bash
# 1. Determine next version number
./gradlew flywayInfo  # Check current state

# 2. Create migration file
touch src/main/resources/db/migration/V{NEXT_VERSION}__{DESCRIPTION}.sql

# 3. Write SQL migration
# - Use IF NOT EXISTS for CREATE statements
# - Include rollback comments for documentation
# - Test SQL in database client first
```

### 2. Testing Migrations

```bash
# Test in development environment
FLYWAY_ENABLED=true KTOR_ENV=production ./gradlew run

# Or run migration manually
./gradlew flywayMigrateVerbose

# Validate migration
./gradlew flywayValidateVerbose
```

### 3. Migration Best Practices

#### SQL Best Practices

```sql
-- ✅ Good: Use IF NOT EXISTS
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE
);

-- ✅ Good: Add columns safely
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'created_at') THEN
        ALTER TABLE users ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- ✅ Good: Create indexes with IF NOT EXISTS
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- ❌ Avoid: Dropping data
DROP TABLE user_sessions;  -- Use with extreme caution

-- ❌ Avoid: Non-reversible changes without backup
ALTER TABLE users DROP COLUMN email;  -- Better to rename/deprecate first
```

#### Performance Considerations

```sql
-- ✅ Good: Add indexes for new queries
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_large_table_status ON large_table(status);

-- ✅ Good: Use transactions for related changes
BEGIN;
    ALTER TABLE users ADD COLUMN department_id UUID;
    CREATE INDEX IF NOT EXISTS idx_users_department ON users(department_id);
COMMIT;

-- ⚠️ Careful: Large data migrations
-- Consider breaking into smaller batches for large tables
```

### 4. Environment Configuration

#### Environment Variables

```bash
# Database connection (matches application.yaml)
DB_HOST=localhost
DB_PORT=5433
DB_NAME=wondernest_prod
DB_USERNAME=wondernest_app
DB_PASSWORD=wondernest_secure_password_dev

# Flyway-specific settings
FLYWAY_ENABLED=true                    # Enable/disable migrations
FLYWAY_BASELINE_ON_MIGRATE=false      # Baseline existing database
FLYWAY_VALIDATE_ON_MIGRATE=true       # Validate on migration
FLYWAY_CLEAN_ON_VALIDATION_ERROR=false # Never auto-clean
FLYWAY_OUT_OF_ORDER=false             # Require sequential order
FLYWAY_TABLE=flyway_schema_history     # Migration history table
```

#### Development vs Production

| Setting | Development | Production |
|---------|------------|------------|
| Automatic migrations | Disabled by default | Enabled |
| Validation | Relaxed | Strict |
| Clean allowed | Yes | No |
| Baseline on migrate | Optional | No |

## Troubleshooting

### Common Issues

#### 1. Permission Denied Errors

```bash
# Error: permission denied for database wondernest_prod
# Location: V2__Complete_Schema.sql
# Line: CREATE SCHEMA IF NOT EXISTS compliance

# Solution: Grant schema creation permissions
docker exec wondernest_postgres psql -U postgres -d wondernest_prod -c "
    GRANT CREATE ON DATABASE wondernest_prod TO wondernest_app;
    ALTER USER wondernest_app CREATEDB;
"
```

#### 2. Migration Failed - Manual Repair

```bash
# Check what failed
./gradlew flywayInfo

# Mark failed migration as resolved (if you fixed the issue manually)
./gradlew flywayRepair

# Try migration again
./gradlew flywayMigrate
```

#### 3. Out of Order Migrations

```bash
# If you need to apply migrations out of order (not recommended)
# Set environment variable temporarily
FLYWAY_OUT_OF_ORDER=true ./gradlew flywayMigrate
```

#### 4. Baseline Existing Database

```bash
# If starting Flyway on existing database
./gradlew flywayBaseline

# Then apply new migrations
./gradlew flywayMigrate
```

### Migration History Commands

```bash
# Check current status
./gradlew flywayInfo

# View detailed migration history
docker exec wondernest_postgres psql -U wondernest_app -d wondernest_prod -c "
    SELECT installed_rank, version, description, installed_on, execution_time, success 
    FROM flyway_schema_history 
    ORDER BY installed_rank;
"

# Check for pending migrations
./gradlew flywayInfo | grep -E "(Pending|Failed)"
```

## Integration with Application

### Automatic Migration on Startup

The application automatically runs migrations on startup in production mode:

```kotlin
// DatabaseFactory.kt
private fun runMigrations() {
    val migrationService = MigrationService(dataSource)
    val migrationsExecuted = migrationService.migrate()
    
    if (migrationsExecuted > 0) {
        logger.info("Database migrations completed: $migrationsExecuted migrations applied")
    }
}
```

### Configuration Loading

Migration settings are loaded from:

1. **Environment variables** (highest priority)
2. **application.yaml** (fallback defaults)
3. **Gradle build script** (for manual tasks)

### Disable Automatic Migrations

```bash
# Temporarily disable automatic migrations
FLYWAY_ENABLED=false ./gradlew run

# Or set in application.yaml
database:
  flyway:
    enabled: false
```

## Advanced Usage

### Repeatable Migrations

For scripts that should run every time they change:

```sql
-- File: R__Update_Views.sql
-- Repeatable migrations start with R__ instead of V__

DROP VIEW IF EXISTS user_summary;
CREATE VIEW user_summary AS
SELECT id, email, created_at, last_login
FROM users
WHERE active = true;
```

### Callbacks

Flyway supports lifecycle callbacks:

```sql
-- beforeMigrate.sql - runs before any migration
-- afterMigrate.sql - runs after any migration
-- beforeEachMigrate.sql - runs before each migration
-- afterEachMigrate.sql - runs after each migration
```

### Migration Testing

Create integration tests for migrations:

```kotlin
@Test
fun testV3Migration() {
    // Apply up to V2
    flyway.migrate("2")
    
    // Verify state before V3
    // Apply V3
    flyway.migrate("3")
    
    // Verify V3 changes
}
```

## Production Deployment

### Pre-deployment Checklist

- [ ] Test migration on staging environment with production data copy
- [ ] Verify migration performance on large datasets
- [ ] Ensure rollback plan exists
- [ ] Backup database before migration
- [ ] Monitor migration execution time
- [ ] Validate application functionality after migration

### Deployment Process

```bash
# 1. Deploy application with new migration files
# 2. Application automatically runs migrations on startup
# 3. Monitor logs for migration success/failure
# 4. Verify application functionality
# 5. Monitor for any performance issues
```

### Emergency Procedures

```bash
# If migration fails in production:
# 1. Check application logs for specific error
# 2. Fix database manually if possible
# 3. Use flywayRepair to mark as resolved
# 4. Or rollback to previous application version
```

---

## Quick Reference

### Most Common Commands

```bash
# Check migration status
./gradlew flywayInfo

# Apply pending migrations  
./gradlew flywayMigrate

# Test server with migrations
KTOR_ENV=production ./gradlew run

# View migration history
docker exec wondernest_postgres psql -U wondernest_app -d wondernest_prod -c "SELECT * FROM flyway_schema_history ORDER BY installed_rank;"
```

### File Naming Quick Check

| ✅ Correct | ❌ Incorrect |
|-----------|-------------|
| `V1__Initial_Schema.sql` | `V1_0__Initial_Schema.sql` |
| `V2_1__Add_User_Table.sql` | `V2-1__Add_User_Table.sql` |
| `V3__Update_Permissions.sql` | `v3__update_permissions.sql` |
| `R__Update_Views.sql` | `R1__Update_Views.sql` |

---

*For more information, see the [official Flyway documentation](https://flywaydb.org/documentation/)*