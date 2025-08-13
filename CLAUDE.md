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