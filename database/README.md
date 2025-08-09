# WonderNest Database Schema

A comprehensive PostgreSQL database schema for WonderNest, a child development tracking platform that combines content curation with passive speech environment monitoring.

## Overview

This database supports:
- **User Management**: Parent accounts, authentication, and family structures
- **Child Profiles**: COPPA-compliant child data with minimal PII collection
- **Content Library**: Curated educational content with safety ratings
- **Audio Analysis**: Privacy-first speech metrics (no raw audio storage)
- **Subscription Management**: Freemium model with multiple tiers
- **Analytics & Insights**: Development tracking and parent dashboards
- **Safety & Compliance**: Parental controls and audit trails

## Architecture

### Schema Organization

```
wondernest_db/
├── core/              -- User management, authentication
├── family/            -- Parent-child relationships, profiles  
├── content/           -- Content library, curation, engagement
├── audio/             -- Speech analysis, sessions, metrics
├── subscription/      -- Billing, plans, payments
├── analytics/         -- Usage tracking, insights, reports
├── safety/            -- Content safety, parental controls
├── ml/                -- Machine learning models, recommendations
└── audit/             -- Audit logs, compliance tracking
```

### Key Design Principles

1. **Privacy by Design**: Minimal data collection, strong encryption, COPPA compliance
2. **Scalability**: Partitioned tables, optimized indexes, horizontal scaling ready
3. **Performance**: Materialized views, intelligent caching, query optimization
4. **Data Integrity**: Strong constraints, referential integrity, audit trails
5. **Compliance**: GDPR/COPPA ready, data retention policies, right to deletion

## Prerequisites

- PostgreSQL 15+
- Superuser access for initial setup
- At least 2GB available disk space
- Connection pooling recommended (PgBouncer)

## Quick Start

### 1. Database Creation

```bash
# Create database (run as postgres superuser)
createdb wondernest_prod

# Or via SQL
psql -U postgres -c "CREATE DATABASE wondernest_prod;"
```

### 2. Schema Setup (Recommended Order)

Execute the SQL files in order:

```bash
# Navigate to database directory
cd /Users/patrykpoborca/Documents/personal_projects/wonder_nest/database

# Run setup scripts in order
psql -U postgres -d wondernest_prod -f 01_create_database.sql
psql -U postgres -d wondernest_prod -f 02_create_tables.sql  
psql -U postgres -d wondernest_prod -f 03_create_indexes.sql
psql -U postgres -d wondernest_prod -f 04_create_functions.sql
psql -U postgres -d wondernest_prod -f 05_create_triggers.sql
psql -U postgres -d wondernest_prod -f 06_seed_data.sql
psql -U postgres -d wondernest_prod -f 07_security_setup.sql
```

### 3. Alternative: Flyway Migration

Use the migration script for automated deployment:

```bash
# Using Flyway CLI
flyway -url=jdbc:postgresql://localhost:5432/wondernest_prod \
       -user=postgres \
       -password=yourpassword \
       -locations=filesystem:migration \
       migrate
```

## File Descriptions

| File | Purpose | Dependencies |
|------|---------|--------------|
| `schema_design.md` | Comprehensive documentation | None |
| `01_create_database.sql` | Database, schemas, extensions, types | None |
| `02_create_tables.sql` | All table definitions with constraints | 01 |
| `03_create_indexes.sql` | Performance indexes and query optimization | 02 |
| `04_create_functions.sql` | Stored procedures and business logic | 02 |
| `05_create_triggers.sql` | Audit triggers and data validation | 04 |
| `06_seed_data.sql` | Reference data and sample content | 05 |
| `07_security_setup.sql` | Roles, permissions, row-level security | 06 |
| `migration/V001__initial_schema.sql` | Flyway-compatible migration | None |

## Database Roles

After setup, the following roles will be created:

| Role | Purpose | Permissions | Connection Limit |
|------|---------|-------------|------------------|
| `wondernest_app` | Main application | Full CRUD on app schemas | 50 |
| `wondernest_analytics` | Business intelligence | Read-only on all schemas | 10 |
| `wondernest_migration` | Database migrations | DDL permissions | 5 |
| `wondernest_backup` | Backup operations | SELECT + replication | 3 |
| `wondernest_monitor` | Health monitoring | System statistics | 5 |

**⚠️ IMPORTANT**: Change default passwords before production use!

```sql
ALTER ROLE wondernest_app PASSWORD 'your_secure_password_here';
```

## Configuration

### Application Configuration

Set these in your application's database connection:

```yaml
# Example application.yaml
database:
  url: jdbc:postgresql://localhost:5432/wondernest_prod
  username: wondernest_app
  password: ${DB_PASSWORD}
  pool_size: 20
  
  # Row-level security context
  connection_init_sql: |
    SET app.current_user_id = ?;
    SET app.encryption_key = ?;
    SET application.user_agent = ?;
```

### PostgreSQL Configuration

Recommended settings for production:

```ini
# postgresql.conf
shared_preload_libraries = 'pg_stat_statements'
log_statement = 'mod'
log_min_duration_statement = 1000
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 32MB
```

## Common Operations

### User Management

```sql
-- Create a new parent user
SELECT core.create_user(
    'parent@example.com',
    '$2a$12$hashed_password',
    'John', 'Doe', 'email', NULL, 'America/New_York'
);

-- Create family and add child
SELECT family.create_family(user_id, 'The Doe Family');
SELECT family.create_child_profile(
    family_id, 'Emma', '2021-03-15', 'female', 'en', 
    ARRAY['animals', 'music']
);
```

### Content Discovery

```sql
-- Get age-appropriate content for a child
SELECT * FROM content.get_age_appropriate_content(
    child_id => 'uuid-here',
    p_content_type => 'video',
    p_limit => 20
);
```

### Analytics

```sql
-- Calculate daily metrics
SELECT analytics.calculate_daily_metrics(child_id, CURRENT_DATE);

-- Get child insights  
SELECT analytics.get_child_insights(child_id, 30); -- 30 days
```

### Audio Session Tracking

```sql
-- Start audio session
SELECT audio.start_session(child_id, 'home', 'device123');

-- End session and record metrics
SELECT audio.end_session(session_id, 0.85); -- quality score
```

## Maintenance

### Daily Tasks

```sql
-- Update table statistics
ANALYZE;

-- Clean up expired sessions
SELECT core.cleanup_expired_sessions();

-- Archive old audio sessions
SELECT audio.archive_old_sessions(90); -- 90 days
```

### Weekly Tasks

```sql
-- Vacuum and reindex
VACUUM ANALYZE;
REINDEX DATABASE wondernest_prod;

-- Check database health
SELECT * FROM admin.get_db_health_metrics();
```

### Monthly Tasks

```sql
-- Check partition maintenance
SELECT admin.create_monthly_partition('content.engagement', CURRENT_DATE);
SELECT admin.create_monthly_partition('audio.sessions', CURRENT_DATE);

-- Review index usage
SELECT * FROM admin.index_usage_stats WHERE usage_level = 'Never used';
```

## Monitoring

### Health Checks

```sql
-- Database connectivity
SELECT 1;

-- Schema integrity
SELECT * FROM admin.validate_security_config();

-- Performance metrics
SELECT * FROM admin.index_usage_stats;
SELECT * FROM admin.trigger_monitoring;
```

### Key Metrics to Monitor

1. **Connection count** - Should stay below limits
2. **Query performance** - Watch for slow queries >1s
3. **Lock contention** - Monitor pg_locks
4. **Partition sizes** - Ensure partitions are reasonable
5. **Index usage** - Remove unused indexes

## Backup Strategy

### Full Backup

```bash
# Full database backup
pg_dump -U wondernest_backup -h localhost wondernest_prod \
        --format=custom --compress=9 \
        --file=wondernest_$(date +%Y%m%d_%H%M%S).dump

# Restore
pg_restore -U postgres -d wondernest_prod wondernest_backup.dump
```

### Incremental Backup

```bash
# WAL archiving setup (postgresql.conf)
archive_mode = on
archive_command = 'cp %p /backup/wal/%f'
```

## Security

### Row-Level Security

The database uses RLS to ensure data isolation:

```sql
-- Users can only access their own family's data
SET app.current_user_id = 'user-uuid-here';
SELECT * FROM family.child_profiles; -- Only shows this user's children
```

### Audit Trail

All data changes are logged:

```sql
-- View audit history for a child
SELECT * FROM audit.activity_log 
WHERE child_id = 'child-uuid' 
ORDER BY timestamp DESC;
```

### Data Retention

Automatic cleanup based on retention policies:

```sql
-- View retention policies
SELECT * FROM audit.data_retention_policies;

-- Manual cleanup (runs automatically)
DELETE FROM audit.activity_log 
WHERE retention_until < CURRENT_TIMESTAMP 
AND legal_hold = FALSE;
```

## Troubleshooting

### Common Issues

#### Connection Issues
```sql
-- Check active connections
SELECT * FROM pg_stat_activity WHERE datname = 'wondernest_prod';

-- Kill hung connections
SELECT pg_terminate_backend(pid) FROM pg_stat_activity 
WHERE state = 'idle in transaction' AND state_change < NOW() - INTERVAL '1 hour';
```

#### Performance Issues
```sql
-- Identify slow queries
SELECT query, calls, mean_time, total_time 
FROM pg_stat_statements 
ORDER BY total_time DESC LIMIT 10;

-- Check for missing indexes
SELECT schemaname, tablename, attname, n_distinct, correlation 
FROM pg_stats 
WHERE schemaname IN ('core', 'family', 'content') 
ORDER BY n_distinct DESC;
```

#### Lock Contention
```sql
-- View current locks
SELECT locktype, database, relation::regclass, mode, granted 
FROM pg_locks 
WHERE NOT granted;
```

### Emergency Procedures

#### Read-Only Mode
```sql
-- Enable read-only mode for maintenance
ALTER DATABASE wondernest_prod SET default_transaction_read_only = on;
```

#### Data Export (GDPR)
```sql
-- Export all user data
COPY (
    SELECT u.email, cp.first_name, dcm.* 
    FROM core.users u
    JOIN family.families f ON f.created_by = u.id
    JOIN family.child_profiles cp ON cp.family_id = f.id  
    JOIN analytics.daily_child_metrics dcm ON dcm.child_id = cp.id
    WHERE u.id = 'user-uuid'
) TO '/tmp/user_data_export.csv' WITH CSV HEADER;
```

## Development

### Local Setup

```bash
# Docker Compose for local development
version: '3.8'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: wondernest_dev
      POSTGRES_USER: postgres  
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database:/docker-entrypoint-initdb.d
```

### Testing

```sql
-- Verify test data exists
SELECT * FROM core.users WHERE email LIKE '%@example.com';

-- Run sample queries
SELECT * FROM content.get_age_appropriate_content(
    (SELECT id FROM family.child_profiles LIMIT 1)
);
```

## Contributing

### Making Schema Changes

1. **Never modify existing migration files**
2. **Create new migration files for changes**
3. **Test in development first**
4. **Update documentation**

Example new migration:
```sql
-- migration/V002__add_feature.sql
ALTER TABLE family.child_profiles 
ADD COLUMN new_field VARCHAR(100);

CREATE INDEX idx_child_profiles_new_field 
ON family.child_profiles(new_field);
```

### Code Style

- Use lowercase with underscores for names
- Always include comments for complex logic
- Use YYYY-MM-DD date format
- Include rollback procedures where possible

## Support

### Getting Help

1. Check this README first
2. Review `schema_design.md` for detailed documentation  
3. Check audit logs for data issues
4. Use monitoring views for performance issues

### Performance Tuning

Common optimization queries:

```sql
-- Table sizes
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname IN ('core','family','content','audio','analytics')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Index efficiency
SELECT indexname, idx_scan, idx_tup_read, idx_tup_fetch,
       pg_size_pretty(pg_relation_size(indexname::regclass)) as size
FROM pg_stat_user_indexes 
WHERE idx_scan < 100 -- Potentially unused
ORDER BY pg_relation_size(indexname::regclass) DESC;
```

---

## License

This database schema is part of the WonderNest platform. All rights reserved.

For questions or support, contact the WonderNest development team.