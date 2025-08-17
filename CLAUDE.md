# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
WonderNest is a COPPA-compliant child development platform with audio monitoring and content curation. The system consists of a Flutter mobile app and KTOR backend with PostgreSQL/Redis.

## Build and Development Commands

### Flutter App (WonderNestApp/)
```bash
# Install dependencies
flutter pub get

# Run app on iOS simulator/Android emulator
flutter run

# Run on specific device
flutter run --device-id [device_id]

# Build for production
flutter build ios --release
flutter build apk --release

# Analyze code for issues
flutter analyze --no-fatal-infos

# Run tests
flutter test

# Update iOS dependencies
cd ios && pod install && cd ..

# Generate code (models, providers)
dart run build_runner build --delete-conflicting-outputs
```

### Backend (Wonder Nest Backend/)
```bash
# Start all services (Docker)
docker-compose up -d

# Run backend locally
./gradlew run

# Build backend
./gradlew build

# Run tests
./gradlew test

# Database setup
./setup-database.sh
./verify-database.sh

# Database migrations (use these instead of manual SQL)
./gradlew flywayInfo        # Check migration status
./gradlew flywayMigrate     # Apply pending migrations
./gradlew flywayValidate    # Validate checksums
./gradlew flywayRepair      # Fix checksum mismatches (use carefully)

# View logs
docker-compose logs -f backend
```

## Architecture Overview

### Frontend Architecture
**State Management**: Riverpod with StateNotifier pattern
- Key providers: `AuthProvider`, `AppModeProvider`, `FamilyProvider`, `ContentProvider`
- All providers located in `/lib/providers/`

**Navigation**: GoRouter with PIN-protected parent routes
- Router configuration: `main.dart:74-257`
- Kid mode is default; parent mode requires PIN verification

**API Integration**:
- Main service: `ApiService` (`/lib/core/services/api_service.dart`)
- Mock fallback: `MockApiService` for offline development
- Auto-fallback when backend unavailable

**Security Model**:
- App starts in Kid Mode by default
- Parent Mode requires PIN entry (`/pin-entry` route)
- 15-minute auto-lock for Parent Mode
- Audio processing stays on-device (privacy-first)

### Backend Architecture
**Tech Stack**: Kotlin, KTOR 3.0, PostgreSQL 16, Redis 7

**Database Schema**:
- `core` schema: users, sessions, families, children
- `content` schema: filters, whitelist, activity
- `compliance` schema: coppa_consent, audit_logs
- `analytics` schema: speech_metrics, development_insights

**Key API Endpoints**:
- Auth: `/api/v1/auth/parent/[register|login|verify-pin]`
- Family: `/api/v1/family/[profile|children]`
- Content: `/api/v1/content/[filters|library|recommendations]`
- Analytics: `/api/v1/analytics/children/{childId}/[daily|insights]`
- COPPA: `/api/v1/coppa/consent`

**Authentication**: JWT with refresh tokens, bcrypt for PIN hashing

## Critical Implementation Details

### Audio Privacy
- All speech recognition happens on-device using `speech_to_text` package
- Only processed transcriptions (no raw audio) sent to backend
- Implementation: `/lib/services/audio_processing_service.dart`

### COPPA Compliance
- Parental consent flow: `/lib/screens/coppa/coppa_consent_screen.dart`
- Minimal data collection policy
- Age verification during child profile creation
- Data retention limits enforced

### Content Safety
- Whitelist-only approach for web content
- YouTube Kids API integration
- Age-appropriate filtering based on child profile
- Real-time monitoring in `mini_game_framework.dart`

## Common Issues & Solutions

### Flutter Issues
- **RangeSlider bounds error**: Values must be clamped to min/max range
- **RenderFlex overflow**: Wrap widgets in Flexible/Expanded
- **Provider not found**: Use ConsumerWidget/ConsumerStatefulWidget
- **iOS build fails**: Run `cd ios && pod install`

### Backend Issues
- **API 404 errors**: Check if endpoint exists in mock service
- **Connection refused**: Verify Docker is running (`docker ps`)
- **Database errors**: Run `./verify-database.sh` to check connection
- **Flyway checksum mismatch**: File was modified after migration - use `./gradlew flywayRepair` carefully or create new migration
- **Migration fails**: Check database logs and never manually edit `flyway_schema_history`
- **"No database found" error**: Ensure PostgreSQL container is running and accessible on port 5433

### Development Tips
- App auto-switches to MockApiService when backend unavailable
- Test PIN: Any 6 digits work in mock mode
- All mock data in `/lib/core/services/mock_api_service.dart`
- Backend runs on `http://localhost:8080`
- Database on port 5433, Redis on 6379

## Environment Configuration

### Flutter App
Uses FlutterSecureStorage for sensitive data:
- `auth_token`, `refresh_token`: JWT tokens
- `parent_pin`: Hashed PIN
- `onboarding_completed`, `parent_account_created`: Boolean flags

### Backend (.env.local)
```
DB_HOST=localhost
DB_PORT=5433
DB_NAME=wondernest_prod
DB_USERNAME=wondernest_app
DB_PASSWORD=wondernest_secure_password_dev
JWT_SECRET=your-secret-key
```

## Database Migration Management

### What Went Wrong Previously
**Critical Issue**: The V2 migration was manually inserted into `flyway_schema_history` instead of using proper Flyway tools. This created:
- Incorrect checksum (-1838916409 vs actual 98952696)
- Zero execution time (impossible for 13KB migration)
- Database/filesystem sync issues
- Failed Flyway validations

**Root Cause**: Bypassed Flyway's migration process and manually manipulated the schema history table.

### Proper Migration Workflow

#### Creating New Migrations
```bash
# 1. Create new migration file with proper naming
# Format: V{version}__{description}.sql
# Example: V3__Add_User_Preferences.sql

# 2. Always validate before applying
./gradlew flywayValidateVerbose

# 3. Check current database state
./gradlew flywayInfo

# 4. Apply migration with verbose output
./gradlew flywayMigrateVerbose

# 5. Verify migration succeeded
./gradlew flywayInfo
```

#### Testing Migrations Locally
```bash
# 1. Start fresh database for testing
docker-compose down
docker volume rm wondernest_postgres_data
docker-compose up -d postgres

# 2. Run all migrations from scratch
./gradlew flywayMigrate

# 3. Validate all checksums
./gradlew flywayValidate

# 4. Check final state
./gradlew flywayInfo
```

#### Handling Migration Conflicts

**Checksum Mismatches**:
```bash
# 1. NEVER modify existing migration files
# 2. If checksum mismatch occurs, investigate why:
./gradlew flywayValidate  # Shows which migration has issues

# 3. Options to resolve:
# Option A: Repair checksum (DANGEROUS - only if file is correct)
./gradlew flywayRepair

# Option B: Create new migration to fix issues
# Create V{next}__Fix_Previous_Migration.sql

# Option C: Reset and reapply (development only)
./gradlew flywayClean flywayMigrate
```

**Migration Ordering Issues**:
```bash
# Check for out-of-order migrations
./gradlew flywayInfo

# If migrations are out of order:
# 1. Create new migration with higher version number
# 2. NEVER reorder existing migrations
# 3. Use descriptive names to avoid confusion
```

#### Production Migration Procedures

**Pre-deployment Checklist**:
1. Test migration on production-like data
2. Backup database before migration
3. Validate migration syntax and logic
4. Check for breaking changes
5. Plan rollback strategy

**Production Commands**:
```bash
# 1. Backup database first
./scripts/backup.sh

# 2. Validate current state
./gradlew flywayInfo

# 3. Dry-run validation
./gradlew flywayValidate

# 4. Apply with monitoring
./gradlew flywayMigrateVerbose

# 5. Verify success
./gradlew flywayInfo
```

#### Emergency Procedures

**If Migration Fails Mid-execution**:
```bash
# 1. Check Flyway history for partial state
./gradlew flywayInfo

# 2. Manually verify database state
docker exec wondernest_postgres psql -U wondernest_app -d wondernest_prod -c "SELECT * FROM flyway_schema_history ORDER BY installed_rank;"

# 3. Fix the issue:
# - Complete the failed migration manually if safe
# - Create repair migration
# - Use flywayRepair if absolutely necessary

# 4. Never manually edit flyway_schema_history unless absolutely critical
```

**Database Recovery**:
```bash
# 1. Restore from backup
./scripts/restore.sh [backup_file]

# 2. Re-run migrations from known good state
./gradlew flywayInfo
./gradlew flywayMigrate

# 3. Validate final state
./gradlew flywayValidate
```

### Migration Best Practices

#### File Management
- **NEVER modify existing migration files** after they've been applied
- Use semantic versioning: V1, V2, V3 (not V1.1, V1.2)
- Descriptive names: `V3__Add_User_Preferences_Table.sql`
- Always include rollback instructions in comments

#### Content Guidelines
```sql
-- V3__Add_User_Preferences.sql
-- Adds user preferences table for storing UI settings
-- 
-- Rollback: DROP TABLE user_preferences; 
-- Dependencies: Requires V2 (users table)
-- Breaking Changes: None

CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    preference_key VARCHAR(100) NOT NULL,
    preference_value TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_preferences_user_id ON user_preferences(user_id);
```

#### Testing Requirements
- Test on empty database (clean install)
- Test on database with existing data
- Verify indexes and constraints work
- Check performance impact of large migrations
- Test rollback procedures

#### Common Pitfalls to Avoid
1. **Manual schema_history manipulation** - Always use Flyway commands
2. **Modifying applied migrations** - Create new migrations instead
3. **Ignoring checksum errors** - These indicate serious sync issues
4. **Running migrations without backups** - Always backup production first
5. **Mixing manual SQL with Flyway** - Choose one approach per environment

### Troubleshooting Migration Issues

#### Flyway Command Failures
```bash
# Database connection issues
./verify-database.sh  # Check if database is accessible

# Permission issues
docker exec wondernest_postgres psql -U wondernest_app -d wondernest_prod -c "\du"  # Check user permissions

# Configuration issues
./gradlew flywayInfo --debug  # Verbose debugging output
```

#### Common Error Messages
- **"No database found"**: Database not running or connection failed
- **"Checksum mismatch"**: File modified after migration applied
- **"Out of order migration"**: Lower version number after higher ones
- **"Failed migration"**: SQL syntax error or constraint violation

## Testing Strategy

### Flutter Testing
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test

# Test specific file
flutter test test/widget_test.dart
```

### Backend Testing
```bash
# All tests
./gradlew test

# Integration tests
./gradlew integrationTest

# With test containers
./gradlew testWithContainers
```

## File Organization

### Flutter App Structure
```
lib/
├── core/           # Core utilities, theme, constants
├── models/         # Data models
├── providers/      # Riverpod state management
├── screens/        # UI screens by feature
├── services/       # Business logic services
└── widgets/        # Reusable UI components
```

### Backend Structure
```
src/main/kotlin/com/wondernest/
├── api/            # REST endpoints
├── config/         # App configuration
├── data/           # Database layer
├── domain/         # Business models
├── services/       # Business services
└── utils/          # Utilities
```