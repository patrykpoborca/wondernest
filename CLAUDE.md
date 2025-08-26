# CLAUDE.md - WonderNest AI Development Guide

This file provides comprehensive guidance to Claude AI when working with the WonderNest codebase, incorporating feature development standards and tracking patterns.

## 🎯 Project Overview
WonderNest is a COPPA-compliant child development platform with audio monitoring and content curation. The system consists of:
- **Frontend**: Flutter mobile app (iOS/Android/Desktop support)
- **Backend**: KTOR 3.0 with Kotlin
- **Database**: PostgreSQL 16 with multiple schemas (core, games, content, analytics, compliance)
- **Cache**: Redis 7

## 📁 AI Guidance Directory Structure

All AI-assisted development is tracked in the `ai_guidance/` directory:

```
ai_guidance/
├── features/                           # Feature-specific documentation
│   └── {feature_name}/
│       ├── feature_description.md      # Business requirements
│       ├── implementation_todo.md       # Technical checklist
│       ├── changelog.md                # Session history
│       ├── api_endpoints.md           # API documentation
│       └── remaining_todos.md         # Incomplete work
├── business_definitions.md            # Domain terminology
└── architecture_decisions/            # ADRs for key decisions
```

## 🚀 Session Start Protocol

### At Each Session Start:
1. **Check for existing work**:
```bash
# List all features with remaining work
find ai_guidance/features -name "remaining_todos.md" -exec grep -l "." {} \;

# Check recent changes
find ai_guidance/features -name "changelog.md" -exec grep -l "$(date +'%Y-%m-%d')" {} \;
```

2. **Review context**:
- Read relevant `feature_description.md`
- Check `changelog.md` for recent work
- Review `implementation_todo.md` progress

3. **Set up tracking** (for new features):
```bash
mkdir -p ai_guidance/features/{feature_name}
# Create required files from templates
```

## 📋 Feature Development Standards

### Feature Documentation Template
Each feature MUST have:

#### feature_description.md
```markdown
# {Feature Name}

## Overview
Brief description of the feature and its business value.

## User Stories
- As a {user type}, I want to {action} so that {benefit}

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Technical Constraints
- Must work offline for mobile
- Must be COPPA compliant
- Must support iOS/Android/Desktop

## Security Considerations
- Authentication requirements
- Data privacy concerns
```

#### implementation_todo.md
```markdown
# Implementation Todo: {Feature Name}

## Pre-Implementation
- [ ] Review business requirements
- [ ] Check existing similar features
- [ ] Design database schema

## Backend Implementation
- [ ] Create/update models
- [ ] Implement services
- [ ] Create API routes
- [ ] Add validation
- [ ] Write tests

## Frontend Implementation
- [ ] Create/update providers
- [ ] Implement screens
- [ ] Add navigation
- [ ] Handle states (loading/error/success)
- [ ] Test on all platforms

## Testing
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing on iOS/Android
```

### Changelog Format
Every coding session MUST add a changelog entry:

```markdown
## [YYYY-MM-DD HH:MM] - Type: {FEATURE|BUGFIX|REFACTOR|TEST|DOCS}

### Summary
One-line description of work done

### Changes Made
- ✅ Completed change
- ⚠️ Change with caveats
- 🐛 Bug discovered

### Files Modified
| File | Change Type | Description |
|------|------------|-------------|
| `/path/to/file` | CREATE/MODIFY | What changed |

### Testing
- Tested: What was tested
- Result: Test outcome

### Next Steps
- What should be done next
```

## 🏗️ Architecture Patterns

### Frontend (Flutter)
**State Management**: Riverpod with StateNotifier
```dart
// Provider pattern
final gameProvider = StateNotifierProvider<GameNotifier, GameState>((ref) {
  return GameNotifier(ref.read(apiServiceProvider));
});
```

**Navigation**: GoRouter with PIN protection
```dart
// Protected routes require parent PIN
GoRoute(
  path: '/parent-dashboard',
  builder: (context, state) => const ParentDashboard(),
  redirect: (context, state) => checkParentAuth(),
)
```

**API Integration**: Service pattern with mock fallback
```dart
// Automatic fallback to mock when backend unavailable
final apiService = ref.watch(apiServiceProvider);
// Automatically uses MockApiService when backend is down
```

### Backend (KTOR)
**Database Access**: Repository pattern
```kotlin
// Use transaction wrapper for all DB operations
fun saveGameData(data: GameData) = transaction {
    // Set schema path for games tables
    exec("SET search_path TO games, public")
    // Perform operations
}
```

**API Routes**: RESTful with versioning
```kotlin
route("/api/v2/games") {
    authenticate("auth-jwt") {
        put("/children/{childId}/data") {
            // Implementation
        }
    }
}
```

## 🔧 Build and Development Commands

### Flutter App (WonderNestApp/)
```bash
# Install dependencies
flutter pub get

# Run app
flutter run                           # Default device
flutter run --device-id [device_id]   # Specific device

# Build
flutter build ios --release
flutter build apk --release
flutter build macos --release

# Testing
flutter test                          # All tests
flutter test test/widget_test.dart    # Specific test

# Code generation
dart run build_runner build --delete-conflicting-outputs

# iOS specific
cd ios && pod install && cd ..

# Analyze code
flutter analyze --no-fatal-infos
```

### Backend (Wonder Nest Backend/)
```bash
# Start services
docker-compose up -d                  # All services
./gradlew run                         # Backend only

# Build and test
./gradlew build
./gradlew test
./gradlew integrationTest

# Database
./setup-database.sh                   # Initial setup
./verify-database.sh                  # Check connection

# Migrations (NEVER edit manually)
./gradlew flywayInfo                 # Check status
./gradlew flywayMigrate              # Apply migrations
./gradlew flywayValidate             # Validate checksums
```

## 🗄️ Database Schema Architecture

### Schema Organization
```sql
-- Core business entities
core.users, core.families, core.children

-- Game system (enhanced architecture)
games.game_registry      -- Available games
games.child_game_instances -- Per-child game access
games.child_game_data     -- Game save data (JSONB)

-- Content filtering
content.filters, content.whitelist

-- Analytics and metrics
analytics.speech_metrics, analytics.development_insights

-- Compliance
compliance.coppa_consent, compliance.audit_logs
```

### Game Data Architecture
Following the proper pattern:
```
GameRegistry → ChildGameInstances → ChildGameData
```

Key tables:
- `games.game_registry`: Master list of available games
- `games.child_game_instances`: Tracks which children have access to which games
- `games.child_game_data`: Stores flexible JSON data with versioning

## 🔐 Security & Privacy

### COPPA Compliance
- Parental consent required for data collection
- Minimal data collection policy
- Age verification during child profile creation
- Data retention limits enforced

### Audio Privacy
- All speech recognition on-device only
- No raw audio transmitted
- Only processed transcriptions sent to backend

### Authentication
- JWT tokens with refresh mechanism
- PIN protection for parent mode
- 15-minute auto-lock for parent features
- Bcrypt hashing for PINs

## 🐛 Common Issues & Solutions

### Flutter Issues
| Issue | Solution |
|-------|----------|
| RangeSlider bounds error | Clamp values to min/max range |
| RenderFlex overflow | Wrap in Flexible/Expanded |
| Provider not found | Use ConsumerWidget/ConsumerStatefulWidget |
| iOS build fails | Run `cd ios && pod install` |

### Backend Issues
| Issue | Solution |
|-------|----------|
| API 404 errors | Check endpoint in MockApiService |
| Connection refused | Verify Docker: `docker ps` |
| Database errors | Run `./verify-database.sh` |
| Schema not found | Tables use qualified names: `games.table_name` |
| Serialization errors | Use `Map<String, String>` not `Map<String, Any>` |

### Migration Issues
| Issue | Solution |
|-------|----------|
| Checksum mismatch | NEVER modify existing migrations |
| Out of order | Create new migration with higher version |
| Failed migration | Check logs, create repair migration |

## 📝 Logging Standards

### Flutter
```dart
// NEVER use print() - Always use Timber
Timber.d('Debug message');           // Debug
Timber.i('Info message');            // Info  
Timber.w('Warning message');         // Warning
Timber.e('Error message: $error');   // Error
```

### Backend
```kotlin
// Use structured logging
logger.info("Operation completed: $operation")
logger.error("Database error", exception)
```

## 🧪 Testing Strategy

### Required Testing
1. **Unit Tests**: All business logic
2. **Integration Tests**: API endpoints
3. **Platform Tests**: iOS, Android, Desktop
4. **Manual Tests**: User flows

### Test Checklist
- [ ] Backend unit tests pass
- [ ] API integration tests pass
- [ ] Flutter widget tests pass
- [ ] iOS simulator testing
- [ ] Android emulator testing
- [ ] Mock mode testing

## 🎯 Quality Checklist

Before marking any feature complete:
- [ ] All todos in implementation_todo.md checked
- [ ] Comprehensive changelog entry added
- [ ] API documentation current
- [ ] Tests passing
- [ ] No remaining_todos or empty
- [ ] Code follows patterns
- [ ] COPPA compliant
- [ ] Works offline (mobile)
- [ ] Error handling comprehensive

## 🚨 Critical Rules

### ALWAYS:
1. Create changelog entries for EVERY session
2. Use proper schema-qualified table names
3. Test on both iOS and Android
4. Use Timber for logging (never print())
5. Handle offline scenarios
6. Follow existing patterns
7. Document assumptions

### NEVER:
1. Skip changelog entries
2. Use Map<String, Any> in JSONB columns
3. Modify existing migrations
4. Commit without testing
5. Store raw audio data
6. Break COPPA compliance
7. Use incorrect domain terms

## 📊 Progress Indicators

Use standardized status indicators in documentation:
- 🚧 In Progress
- ✅ Complete
- ⚠️ Complete with caveats
- 🐛 Has bugs
- 📝 Needs documentation
- 🔄 Needs refactoring
- ❌ Blocked

## 🔍 Useful Commands

```bash
# Find incomplete features
grep -r "remaining_todos.md" ai_guidance/features/

# Check today's changes
find ai_guidance -name "changelog.md" -exec grep -l "$(date +'%Y-%m-%d')" {} \;

# List all game data for a child
PGPASSWORD=wondernest_secure_password_dev psql -h localhost -p 5433 -U wondernest_app -d wondernest_prod -c "SELECT * FROM games.child_game_data WHERE child_game_instance_id IN (SELECT id FROM games.child_game_instances WHERE child_id = 'UUID');"

# Check backend logs
docker-compose logs -f backend --tail=100

# Kill process on port 8080
lsof -ti:8080 | xargs kill -9
```

## 🎓 Example Session Flow

1. **Start**: Check for existing work
2. **Context**: Review feature requirements
3. **Implementation**: Follow todo checklist
4. **Testing**: Verify on all platforms
5. **Documentation**: Update changelog
6. **End**: Document remaining work

## 📚 Key File Locations

### Frontend
- Router: `main.dart:74-257`
- API Service: `/lib/core/services/api_service.dart`
- Mock Service: `/lib/core/services/mock_api_service.dart`
- Providers: `/lib/providers/`
- Game Services: `/lib/games/*/services/`

### Backend
- Routes: `/src/main/kotlin/com/wondernest/api/`
- Services: `/src/main/kotlin/com/wondernest/services/`
- Tables: `/src/main/kotlin/com/wondernest/data/database/table/`
- Config: `/src/main/kotlin/com/wondernest/config/`

## 🔄 Git Workflow

### Commit Message Format
```
{type}({scope}): {subject}

{body}

{footer}
```

Types: feat, fix, docs, style, refactor, test, chore
Scope: Feature name or module

Example:
```
feat(sticker-book): add UPSERT logic for game saves

- Fixed saveGameData to handle updates with versioning
- Changed from INSERT-only to proper UPSERT pattern
- Maintains version history and timestamps

Fixes update failures during sticker book editing
```

---

**Remember**: This is a living document. Update it as patterns emerge and the project evolves. The goal is consistency, clarity, and maintainability across all AI-assisted development sessions.